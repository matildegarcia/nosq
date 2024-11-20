const
  MAX_LARGO_TEXTO = 100;    { tamaño máximo de los textos }
  MAX_LARGO_CLAVE = 10;     { largo máximo de una clave }
  MAX_USUARIOS = 10;        { cantidad máxima de usuarios en el gestor }

type
    { Una cadena de Texto que puede ser usada para nombres, contraseñas, etc.}
    Texto = record 
        tex : array[1..MAX_LARGO_TEXTO] of char;
        tope : 0..MAX_LARGO_TEXTO
        end;

    { Tipo de cadena de caracteres exclusivamente para el uso de clves de cifrado }
    Clave = record 
        cla : array[1..MAX_LARGO_CLAVE] of char;
        tope : 0..MAX_LARGO_CLAVE
        end;

  { representa una lista de servicios, donde en cada nodo almacena un servicio,
  junto a su contraseña cifrada} 
  TServicios = ^TServicio;
  TServicio = record
    nombreServicio: Texto;
    contraServCifrada: Texto; // Contraseña cifrada
    sig : TServicios  
  end;

  { Representa un usuario del gestor de contraseñas }
  TUsuario = record
    usuario: Texto;
    serviciosUsuario: TServicios
  end;

  { Estructura pirncipal, donde se almacenan los usuarios y sus servicios }
  TGestorContrasenia = record
        usuarios: array [1..MAX_USUARIOS] of TUsuario;
        tope:0..MAX_USUARIOS
  end;

  { Estructura auxiliar, para devolver un servicio }
  TMaybeServ = record case existe:boolean of 
                    true : (coserv : Texto);
                    false : ()
            end;

  { Estructuras auxiliares para devolver la contraseña en texto claro de un servicio }
  { El enumerado TResp tiene los valores:
      serv: para cuando el servicio existe
      noserv: para cuando el servicio no existe
      nocontra: cuando falla la autenticación del usuario}
  TResp = (serv,noserv,nocontra);
  TRes = record case resp:TResp of 
           serv : (cserv:Texto);
           noserv : ();
           nocontra : ();
        end;

  { Las siguientes son estructuras auxiliares usadas para la autenticación de
  los usuairos }
  { Almacena la información de autenticación de un usuario del sistema: Nombre, clave de Ceasar para cifrar la master key y la master key cifrada }
  TUsuarioClave = record 
                        usuario : Texto;
                        desp : 0..25;
                        masterCifrada : Clave;
                    end;

  { Estructura donde se almacena la información de autenticación de los usuarios del gestor}
  TAutenticacion = record
        usuarios: array [1..MAX_USUARIOS] of TUsuarioClave;
        tope:0..MAX_USUARIOS
  end;

  { Respuesta al autenticar, en caso de autenticación Ok, se devuelve la key utilizada para cifrar las claves de los servicios }
  TRespAutenticacion = record case autenticacionOK : boolean of
                                true : (master : Clave);
                                false : ();
                        end;

function igualTexto(tx1,tx2 : Texto) : boolean;
{ Devuelve True si los dos textos ingresados son iguales, 
  false en caso contrario }
var
    i:integer;
    eq:boolean;
begin
    i:=1;
    if tx1.tope <> tx2.tope then eq := false
    else
        begin
            while (i<=tx1.tope) and (tx1.tex[i] = tx2.tex[i]) do
                i:=i+1;
           eq := i > tx1.tope
        end;
    igualTexto := eq
end;

function igualClave(cl1,cl2 : Clave) : boolean;
{ Devuelve True si las dos claves ingresadas son iguales, 
  false en caso contrario }
var
    i:integer;
    eq:boolean;
begin
    i:=1;
    if cl1.tope <> cl2.tope then eq := false
    else
        begin
            while (i<=cl1.tope) and (cl1.cla[i] = cl2.cla[i]) do
                i:=i+1;
           eq := i > cl1.tope
        end;
    igualClave := eq
end;


// procedimientos de lectura
procedure leerTexto(var textoPlano:Texto);
var
    c:char;
    i:integer;
begin
    i := 1;
    read(c);
    while c <> '.'do
    begin
        textoPlano.tex[i] := c;
        i := i+1;
        read(c)
    end;
    readln;
    textoPlano.tope := i-1
end;

procedure leerClave(var cl:Clave);
var
    c:char;
    i:integer;
begin
    i := 1;
    read(c);
    while c <> '.'do
    begin
        cl.cla[i] := c;
        i := i+1;
        read(c)
    end;
    readln;
    cl.tope := i-1
end;

// procedimientos de despliegue
procedure desplegarTexto(texto: Texto);
var
    i:integer;
begin
    for i:= 1 to texto.tope do
        write(texto.tex[i]);
    writeln
end;

procedure desplegarClave(cl: Clave);
var
    i:integer;
begin
    for i := 1 to cl.tope do
        write(cl.cla[i]);
    writeln
end;

procedure desplegarServicios(servs:TServicios);
begin
    while servs <> nil do
    begin
        desplegarTexto(servs^.nombreServicio);
        // write(' -> ');
        // writeln;
        servs := servs^.sig
    end;
    writeln
end;

procedure desplegarUsuarioClave(us:TUsuarioClave);
begin
    with us do
    begin
        write('Id de usuario: ');
        desplegarTexto(usuario);
        writeln('Desplazamiento: ', desp:0);
        write('Master cifrada: ');
        desplegarClave(masterCifrada)
    end
end;

procedure desplegarAuthInfo(authInfo:TAutenticacion);
var
    i:integer;
begin
    for i:= 1 to authInfo.tope do
        desplegarUsuarioClave(authInfo.usuarios[i]);
end;

function sustituirLetra(letra : char; 
                        desplazamiento : integer) : char;
{ Esta función devuelve la letra correspondiente a aplicar el 
  desplazamiento sobre la letra pasada como parámetro}
var 
	des : integer;
begin
	des := desplazamiento;
	case letra of
		'a'..'z':
			sustituirLetra := chr((ord(letra) - ord('a') + des) mod 26 + ord('a'));
		'A'..'Z':
			sustituirLetra := chr((ord(letra) - ord('A') + des) mod 26 + ord('A'));
		else
			sustituirLetra := letra; 
	end
end;

procedure cifradoCesarClave(textoOrig : Clave;  
                            desp : integer; 
                            var textoObj: Clave);
{ Dada una clave (`textoOrig`) y un desplazamiento (`desp`), devuelve 
  en `textoObj` la clave cifrada utilizando el algoritmo César }
var
	i : integer;
begin
    for i := 1 to textoOrig.tope do
        textoObj.cla[i] := sustituirLetra(textoOrig.cla[i],desp);
    textoObj.tope := textoOrig.tope
end;

procedure autenticarUsuario (usuario : Texto; 
                            clave : Clave; 
                            authInfo : TAutenticacion; 
                            var resp : TRespAutenticacion);
{ Dado un usuario y su clave maestra, devuelve en autenticacionOK 
  true en caso de que el usuario exista y la contraseña sea válida. 
  En ese caso además deuvleve en master la clave que debe utilizarse 
  para cifrar y descifrar las contraseñas de los servicios }
var i : integer;
    claveCifrada : Clave;
begin
    i := 1;
    while (i <= authInfo.tope) and not igualTexto(usuario, authInfo.usuarios[i].usuario) do
        i := i + 1;
    if (i <= authInfo.tope) then
    begin
        cifradoCesarClave(clave, authInfo.usuarios[i].desp, claveCifrada);
        if (igualClave(claveCifrada, authInfo.usuarios[i].masterCifrada)) then
        begin
            resp.autenticacionOK := true;
            resp.master := clave
        end
        else
            resp.autenticacionOK := false
    end
    else
        resp.autenticacionOK := false
end;

procedure agregarInfoAutenticacion(us : Texto; 
                                   cl : Clave; 
                                   var authInfo : TAutenticacion);
{ pre : el usuario us no existe y hay lugar en authInfo }
{ Esta función recibe el nombre de un usuario y su clave maestra y 
  lo almacena en la estructura auxiliar authInfo para poder 
  autenticarlo más adelante }
 var claveCifrada : Clave;
     despl : integer;
begin
    authInfo.tope := authInfo.tope + 1;
    despl := trunc(random(26));
    // despl := 5;
    cifradoCesarClave(cl,despl,claveCifrada);

    with authInfo.usuarios[authInfo.tope] do
    begin   
        usuario :=  us;
        desp := despl;
        masterCifrada := claveCifrada;
    end
 end;