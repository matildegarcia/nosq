procedure cifradoVigenere(textoPlano: Texto; cl: Clave; var textoCifrado: Texto);
var
  i, desplazamiento: integer;
begin
  textoCifrado.tope := textoPlano.tope;
  for i := 1 to textoPlano.tope do
  begin
    desplazamiento := ord(cl.cla[(i - 1) mod cl.tope + 1]) - ord('a');
    textoCifrado.tex[i] := sustituirLetra(textoPlano.tex[i], desplazamiento);
  end;
end;

procedure descifradoVigenere(textoCifrado: Texto; cl: Clave; var textoPlano: Texto);
var
  i, desplazamiento: integer;
begin
  textoPlano.tope := textoCifrado.tope;
  for i := 1 to textoCifrado.tope do
  begin
    desplazamiento := -(ord(cl.cla[(i - 1) mod cl.tope + 1]) - ord('a'));
    textoPlano.tex[i] := sustituirLetra(textoCifrado.tex[i], desplazamiento);
  end;
end;

procedure crearGestor(var gc: TGestorContrasenia; var authInfo: TAutenticacion);
begin
  gc.tope := 0;
  authInfo.tope := 0;
end;

procedure agregarUsuario(us: Texto; cl: Clave; var gc: TGestorContrasenia; 
                         var authInfo: TAutenticacion; var full, existe: boolean);
var
  i: integer;
begin
  existe := false;
  full := gc.tope = MAX_USUARIOS;
  if not full then
  begin
    for i := 1 to gc.tope do
      if igualTexto(gc.usuarios[i].usuario, us) then
        existe := true;

    if not existe then
    begin
      gc.tope := gc.tope + 1;
      gc.usuarios[gc.tope].usuario := us;
      gc.usuarios[gc.tope].serviciosUsuario := nil;
      agregarInfoAutenticacion(us, cl, authInfo);
    end;
  end;
end;

procedure agregarServicioUsuario(us: Texto; master: Clave; authInfo: TAutenticacion; 
                                  servn: Texto; co: Texto; 
                                  var gc: TGestorContrasenia; var res: TRes);
var
  i: integer;
  autenticacion: TRespAutenticacion;
  nuevoServicio, servicioActual: TServicios;
  servicioExiste: boolean;
  coCifrada: Texto;
begin
  autenticarUsuario(us, master, authInfo, autenticacion);
  if not autenticacion.autenticacionOK then
    res.resp := nocontra
  else
  begin
    // Buscar usuario
    i := 1;
    while (i <= gc.tope) and not igualTexto(gc.usuarios[i].usuario, us) do
      i := i + 1;

    if i <= gc.tope then
    begin
      // Verificar si el servicio ya existe
      servicioExiste := false;
      servicioActual := gc.usuarios[i].serviciosUsuario;
      while (servicioActual <> nil) and not servicioExiste do
      begin
        servicioExiste := igualTexto(servicioActual^.nombreServicio, servn);
        servicioActual := servicioActual^.sig;
      end;

      if servicioExiste then
        res.resp := noserv
      else
      begin
        // Crear y agregar el nuevo servicio al final de la lista
        cifradoVigenere(co, autenticacion.master, coCifrada);
        new(nuevoServicio);
        nuevoServicio^.nombreServicio := servn;
        nuevoServicio^.contraServCifrada := coCifrada;
        nuevoServicio^.sig := nil;

        if gc.usuarios[i].serviciosUsuario = nil then
          gc.usuarios[i].serviciosUsuario := nuevoServicio
        else
        begin
          servicioActual := gc.usuarios[i].serviciosUsuario;
          while servicioActual^.sig <> nil do
            servicioActual := servicioActual^.sig;
          servicioActual^.sig := nuevoServicio;
        end;

        res.resp := serv;
      end;
    end
    else
      res.resp := nocontra;
  end;
end;


procedure contraseniaServicio(us: Texto; master: Clave; servn: Texto; 
                               gc: TGestorContrasenia; authInfo: TAutenticacion; 
                               var res: TRes);
var
  i: integer;
  autenticacion: TRespAutenticacion;
  servicioActual: TServicios;
  textoDescifrado: Texto;
begin
  autenticarUsuario(us, master, authInfo, autenticacion);
  if not autenticacion.autenticacionOK then
    res.resp := nocontra
  else
  begin
    i := 1;
    while (i <= gc.tope) and not igualTexto(gc.usuarios[i].usuario, us) do
      i := i + 1;

    if i <= gc.tope then
    begin
      servicioActual := gc.usuarios[i].serviciosUsuario;
      while (servicioActual <> nil) and not igualTexto(servicioActual^.nombreServicio, servn) do
        servicioActual := servicioActual^.sig;

      if servicioActual = nil then
        res.resp := noserv
      else
      begin
        descifradoVigenere(servicioActual^.contraServCifrada, master, textoDescifrado);
        res.resp := serv;
        res.cserv := textoDescifrado;
      end;
    end
    else
      res.resp := noserv;
  end;
end;

procedure serviciosUsuario(us: Texto; master: Clave; gc: TGestorContrasenia; 
                           authInfo: TAutenticacion; var servs: TServicios; 
                           var existe: boolean);
var
  i: integer;
  autenticacion: TRespAutenticacion;
begin
  autenticarUsuario(us, master, authInfo, autenticacion);
  if not autenticacion.autenticacionOK then
    existe := false
  else
  begin
    // Buscar usuario
    i := 1;
    while (i <= gc.tope) and not igualTexto(gc.usuarios[i].usuario, us) do
      i := i + 1;

    if i <= gc.tope then
    begin
      // Retornar la lista de servicios
      servs := gc.usuarios[i].serviciosUsuario;
      existe := true;
    end
    else
      existe := false;
  end;
end;
