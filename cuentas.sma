/*
CREATE TABLE cuentas 
(
    id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY ,
	nombre varchar(32) NOT NULL UNIQUE,
	password varchar(34) NOT NULL, 
	registro timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	ultima timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
	asesinatos int(10) DEFAULT '0',
	muertes int(10) DEFAULT '0',
	headshots int(10) DEFAULT '0',
	experiencia int(10) DEFAULT '0',
	nivel int(10) DEFAULT '0',
	reset int(10) DEFAULT '0'
);
*/
#include <amxmodx>
#include <fakemeta>
#include <sqlx>
#define MYSQL_HOST "127.0.0.1"
#define MYSQL_USER "user"
#define MYSQL_PASS "password"
#define MYSQL_DATEBASE "database"
new const TABLA[ ] = "cuentas"; 
#define TAG "\g[ZGaming.CL]\n"
new Handle:g_hTuple;const PDATA_SAFE = 2;const OFFSET_CSTEAMS = 114;const OFFSET_LINUX = 5;enum{FM_CS_TEAM_UNASSIGNED = 0,FM_CS_TEAM_T,FM_CS_TEAM_CT,FM_CS_TEAM_SPECTATOR}
enum{REGISTRAR_CUENTA,LOGUEAR_CUENTA,CARGAR_DATOS,GUARDAR_DATOS,ChequearC,CUENTAS_TOTAL}; enum _:DataID {DESCONECTADO = 0,REGISTRADO,LOGUEADO};enum _:DATOS{Tipo[20]}
new const ESTADOS[DataID][DATOS] = {{ "\dNo Registrado" },{ "\wRegistrado" },{ "\yLogueado"}};new g_estado,Estado[33];
new g_sql_error[512],g_top_menu,g_block_top_menu;

#define PLUGIN  "Sistema de cuentas"
#define VERSION "1.0"
#define AUTHOR  "Author"
#define SiguienteNivel(%1)    (%1 + 1) * 100
#define MAX_LEVEL 45


enum _:Datos
{
	DATOS_ID,
	DATOS_NOMBRE[32],
	DATOS_PASSWORD[32],
	DATOS_EXP,
	DATOS_NIVEL,
	DATOS_RESET,
	DATOS_REGISTRO[32],
	DATOS_ULTIMA[32],
	DATOS_ASESINATOS,
	DATOS_MUERTES,
	DATOS_HEADSHOTS,
	DATOS_VINCULADO
}
new g_datos[33][Datos]
new iCount = -1;
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("DeathMsg", "Event_DeathMsg", "a")
	register_clcmd("say test" , "Menu_Perfil")

	register_message(get_user_msgid("ShowMenu"), "TextMenu");register_message(get_user_msgid("VGUIMenu"), "VGUIMenu2")
	register_clcmd("chooseteam", "clcmd_changeteam");register_clcmd("jointeam", "clcmd_changeteam")
	register_clcmd("CREAR_PASSWORD", "crear_registro" );register_clcmd( "LOGUEAR_PASSWORD", "log_password" );
   	MySQLx_Init( );

   	register_clcmd("say top15", "clcmd_Top15");register_clcmd("say /top15", "clcmd_Top15")
   	register_clcmd("say reset", "Menu_Reset");register_clcmd("say /reset", "Menu_Reset")
   	set_task(0.4, "sqlLoadTop");
}
public clcmd_changeteam(id)
{
	static team
	team = fm_cs_get_user_team(id)
	if (team == FM_CS_TEAM_SPECTATOR && Estado[id] == REGISTRADO || team == FM_CS_TEAM_UNASSIGNED && Estado[id] == REGISTRADO) return PLUGIN_CONTINUE;
	if (team == FM_CS_TEAM_SPECTATOR && Estado[id] == LOGUEADO || team == FM_CS_TEAM_UNASSIGNED && Estado[id] == LOGUEADO) Menu_Ingresar(id)
	else if (team == FM_CS_TEAM_SPECTATOR && Estado[id] == DESCONECTADO || team == FM_CS_TEAM_UNASSIGNED && Estado[id] == DESCONECTADO) Menu_Spec(id)
	else Menu_Perfil(id)
	return PLUGIN_HANDLED;
}
public Menu_Perfil(id)
{
	new Float:EXP_ACTUAL = float(g_datos[id][DATOS_EXP])
	new Float:NECESARIO = float(SiguienteNivel(g_datos[id][DATOS_NIVEL]))
	new Float:PORCENTAJE = (EXP_ACTUAL * 100.0) / NECESARIO
	new menu = menu_create("Mis estadisticas", "Menu_Perfil_Cases")

	menu_addtext2( menu, fmt( "\wID:\y #%d", 						g_datos[id][DATOS_ID] ) );
	menu_addtext2( menu, fmt( "\wNombre:\y %s", 					g_datos[id][DATOS_NOMBRE] ) );
	menu_addtext2( menu, fmt( "\wContraseña:\y %s", 				g_datos[id][DATOS_PASSWORD] ) );
	menu_addtext2( menu, fmt( "\wAsesinatos:\y %d", 				g_datos[id][DATOS_ASESINATOS] ) );
	menu_addtext2( menu, fmt( "\wHeadshots:\y %d", 					g_datos[id][DATOS_HEADSHOTS] ) );
	menu_addtext2( menu, fmt( "\wMuertes:\y %d", 					g_datos[id][DATOS_MUERTES] ) );
	menu_addtext2( menu, fmt( "\wFecha de Registro:\y %s",			g_datos[id][DATOS_REGISTRO] ) );
	menu_addtext2( menu, fmt( "\wFecha de Ultima:\y %s", 			g_datos[id][DATOS_ULTIMA] ) );

	menu_addtext2( menu, fmt( "\wExperiencia:\y %d/%d (%.2f%%)", 	g_datos[id][DATOS_EXP], SiguienteNivel(g_datos[id][DATOS_NIVEL]),PORCENTAJE ) );
	menu_addtext2( menu, fmt( "\wNivel:\y %d/%d", 					g_datos[id][DATOS_NIVEL],MAX_LEVEL ) );
	menu_addtext2( menu, fmt( "\wResets:\y %d", 					g_datos[id][DATOS_RESET],MAX_LEVEL ) );

	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente" );
	menu_setprop(menu, MPROP_BACKNAME, "Atras" );
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}
public Menu_Perfil_Cases( iId, iMenu, iItem )
{
	menu_destroy( iMenu );

	if ( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;

	return PLUGIN_HANDLED;
}

public Event_DeathMsg() {
	new attacker = read_data(1)
	new victim = read_data(2)
	new hs = read_data(3)

	if(hs) {g_datos[attacker][DATOS_HEADSHOTS]++;g_datos[attacker][DATOS_ASESINATOS]++;}
	
	if(!is_user_alive(attacker)) return;
	g_datos[attacker][DATOS_ASESINATOS]++;g_datos[victim][DATOS_MUERTES]++
	guardar_datos(attacker);guardar_datos(victim)

	CheckEXP(attacker, 1, "xd")
}
public client_putinserver(id)
{
	Total_Cuentas(id)
	get_user_name( id, g_datos[ id ][ DATOS_NOMBRE ], charsmax( g_datos[ ][ DATOS_NOMBRE ] ) );
	ChequearCuenta(id)
}
public client_disconnected(id)
{
	if( g_estado & (1<<id) ) 
   	{
   	guardar_datos( id );    
   	g_estado &= ~(1<<id);
   	}
	if(Estado[id] == LOGUEADO)
	guardar_datos(id)

	Estado[id] = DESCONECTADO
   	g_datos[ id ][ DATOS_NOMBRE ] = '^0';
   	g_datos[ id ][ DATOS_PASSWORD ] = '^0';
}
public MySQLx_Init( )
{
    g_hTuple = SQL_MakeDbTuple( MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATEBASE );
    
    if( !g_hTuple ) 
    {
        log_to_file( "SQL_ERROR.txt", "No se pudo conectar con la base de datos." );
        return pause( "a" );
    }
    
    return PLUGIN_CONTINUE;
}
public plugin_end()
	SQL_FreeHandle( g_hTuple ); 

public Menu_Spec( id ) {
    new len[3500], menu 
    formatex(len, charsmax(len), "\wSistema de cuentas^n\rRegistro y guardado de datos^n\yNombre: \y%s^n\rTu estas: %s^n",
    g_datos[ id ][ DATOS_NOMBRE ],ESTADOS[Estado[id]][Tipo]) 
    menu = menu_create(len, "Menu_Spec_Handler")
    
    formatex(len, charsmax(len), "\w %s^n",Estado[id] == REGISTRADO ? "Ingresar" : "Registrar")
    menu_additem(menu, len, "1")

    if(Estado[id] == REGISTRADO)
    {
    	menu_addtext2( menu, fmt( "\wFecha de Registro:\y %s",			g_datos[id][DATOS_REGISTRO] ) );
    	menu_addtext2( menu, fmt( "\wFecha de Ultima:\y %s^n", 			g_datos[id][DATOS_ULTIMA] ) );
    }
    menu_addtext2( menu, fmt( "\wHay \d%d \yusuarios registrados", 			iCount ));

    menu_setprop( menu, MPROP_EXIT, MEXIT_NEVER );
    menu_display( id, menu );
    return PLUGIN_HANDLED;
}

public Menu_Spec_Handler( id, menu, item ) 
{
    switch( item ) 
    {
        case 0: 
        {
        	if(Estado[id] == REGISTRADO)client_cmd( id, "messagemode LOGUEAR_PASSWORD" );
        	else client_cmd( id, "messagemode CREAR_PASSWORD" );
        }
    }
    return PLUGIN_HANDLED;
}

public crear_registro(id)
{
	read_args(g_datos[id][DATOS_PASSWORD], charsmax(g_datos[][DATOS_PASSWORD]));remove_quotes(g_datos[id][DATOS_PASSWORD]); trim(g_datos[id][DATOS_PASSWORD])
	
	if(equal(g_datos[id][DATOS_PASSWORD], "") || contain(g_datos[id][DATOS_PASSWORD], " ") != -1) return 1;
	else 
	{
		new text[3500]
		formatex(text, charsmax(text), "\wDeseas confirmar que tu contraseña sea \r%s \w?", g_datos[id][DATOS_PASSWORD])
		new menu = menu_create(text, "funcion_registrarse")
		menu_additem(menu, "\wSi, confirmar", "1")
		menu_additem(menu, "\wNo, rechazar y cambiar^n^n\rRecuerda Que Esta Sera Tu Clave Para Entrar Al Servidor^n\rNo podras ingresar al servidor con otra clave^n\rTe pedimos que sea una contraseña que recuerdes^n\rDe lo contrario, No podras entrar", "2")
		menu_display(id, menu)
	}
	
	return 1
}
public funcion_registrarse(id, menu, item)
{
	if(item == MENU_EXIT){menu_destroy(menu);return PLUGIN_HANDLED;}
	
	switch(item)
	{
		case 0:
		{
	    new szQuery[ 3500 ], iData[ 2 ];iData[ 0 ] = id;iData[ 1 ] = REGISTRAR_CUENTA;	    
	    formatex( szQuery, charsmax( szQuery ), "INSERT INTO `%s` (Nombre, Password,ultima) VALUES (^"%s^", ^"%s^",now())", TABLA,g_datos[ id ][ DATOS_NOMBRE ], g_datos[id][DATOS_PASSWORD]);
	    SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
	    return PLUGIN_HANDLED;
		}
		case 1: client_cmd(id,"messagemode CREAR_PASSWORD")
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public log_password( id ) {
    read_args( g_datos[id][DATOS_PASSWORD], charsmax( g_datos[][DATOS_PASSWORD] ) )
    remove_quotes( g_datos[id][DATOS_PASSWORD] );trim( g_datos[id][DATOS_PASSWORD] );
    new szQuery[ 3500 ], iData[ 2 ];
    iData[ 0 ] = id;
    iData[ 1 ] = LOGUEAR_CUENTA;
        
    formatex( szQuery, charsmax( szQuery ), "SELECT * FROM `%s` WHERE nombre=^"%s^" AND password=^"%s^"", TABLA,g_datos[id][DATOS_NOMBRE], g_datos[id][DATOS_PASSWORD]);
    SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
    
    return PLUGIN_HANDLED;
}
stock fm_cs_get_user_team(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return FM_CS_TEAM_UNASSIGNED;
	
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}
public DataHandler( failstate, Handle:Query, error[ ], error2, data[ ], datasize, Float:time ) {
    static id;id = data[ 0 ];
    if( !is_user_connected( id ) )return;
    switch( failstate ) 
    {
        case TQUERY_CONNECT_FAILED: 
        { 
        	log_to_file( "SQL_LOG_TQ.txt", "Error en la conexion al MySQL [%i]: %s", error2, error );
        	return;
        }
        case TQUERY_QUERY_FAILED: 
        {
        	log_to_file( "SQL_LOG_TQ.txt", "Error en la consulta al MySQL [%i]: %s", error2, error );
        }
    }
    
    switch( data[ 1 ] ) {
        case REGISTRAR_CUENTA: {
            if( failstate < TQUERY_SUCCESS ) {
                if( containi( error, "nombre" ) != -1 ) print_EasyChat(id, "%s El usuario ya existe",TAG)
                else print_EasyChat(id, "%s Error al crear la cuenta, intenta nuevamente",TAG)
                client_cmd( id, "spk buttons/button10.wav" );ChequearCuenta( id );
            }
            else 
            {
                print_EasyChat(id, "%s Tu cuenta ha sido creada!",TAG)
                new szQuery[ 3500 ], iData[ 2 ];iData[ 0 ] = id;iData[ 1 ] = CARGAR_DATOS;
                formatex( szQuery, charsmax( szQuery ), "SELECT * FROM `%s` WHERE nombre=^"%s^"",TABLA,g_datos[id][DATOS_NOMBRE] );SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
                Estado[id] = LOGUEADO
            }
            
        }
		case LOGUEAR_CUENTA: 
		{
			if( SQL_NumResults( Query ) )
			{
				g_datos[id][DATOS_ID] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "id" ) ); 
				SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "nombre" ), g_datos[id][DATOS_NOMBRE], charsmax( g_datos[][DATOS_NOMBRE]) );
				SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "password" ), g_datos[id][DATOS_PASSWORD], charsmax( g_datos[][DATOS_PASSWORD]) );
				SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "registro" ), g_datos[id][DATOS_REGISTRO], charsmax( g_datos[][DATOS_REGISTRO]) );
				SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "ultima" ), g_datos[id][DATOS_ULTIMA], charsmax( g_datos[][DATOS_ULTIMA]) );

				g_datos[id][DATOS_ASESINATOS] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "asesinatos" ) );
				g_datos[id][DATOS_HEADSHOTS] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "headshots" ) );
				g_datos[id][DATOS_MUERTES] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "muertes" ) );

				g_datos[id][DATOS_EXP] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "experiencia" ) );
				g_datos[id][DATOS_NIVEL] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "nivel" ) );
				g_datos[id][DATOS_RESET] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "reset" ) );
				Estado[id] = LOGUEADO
				g_estado |= (1<<id);
				Menu_Ingresar(id)
			}
			else 
			{
				print_EasyChat(id, "%s Contraseña incorrecta!",TAG)
				client_cmd( id, "spk buttons/button10.wav" );
				ChequearCuenta( id );
			}
        }
		case CARGAR_DATOS: 	
		if( SQL_NumResults( Query ) )
		{ 
			g_datos[id][DATOS_ID] = SQL_ReadResult( Query, 0 );
			SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "registro" ), g_datos[id][DATOS_REGISTRO], charsmax( g_datos[][DATOS_REGISTRO]) );
			SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "ultima" ), g_datos[id][DATOS_ULTIMA], charsmax( g_datos[][DATOS_ULTIMA]) );
			Estado[id] = LOGUEADO;
		}
		case GUARDAR_DATOS: 
		{
			if( failstate < TQUERY_SUCCESS )
			server_print("[Cuentas] Error en el guardado de datos." );
			else
			return; 
		}
      	case ChequearC: 
      	{
      		if(SQL_NumResults(Query)) 
      		{ 
      			g_datos[id][DATOS_ID] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "id" ) ); 
      			SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "nombre" ), g_datos[id][DATOS_NOMBRE], charsmax( g_datos[][DATOS_NOMBRE]) );
      			SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "password" ), g_datos[id][DATOS_PASSWORD], charsmax( g_datos[][DATOS_PASSWORD]) );
      			SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "registro" ), g_datos[id][DATOS_REGISTRO], charsmax( g_datos[][DATOS_REGISTRO]) );
      			SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "ultima" ), g_datos[id][DATOS_ULTIMA], charsmax( g_datos[][DATOS_ULTIMA]) );
      			g_datos[id][DATOS_ASESINATOS] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "asesinatos" ) );
      			g_datos[id][DATOS_HEADSHOTS] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "headshots" ) );
      			g_datos[id][DATOS_MUERTES] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "muertes" ) );
      			g_datos[id][DATOS_EXP] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "experiencia" ) );
      			g_datos[id][DATOS_NIVEL] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "nivel" ) );
      			g_datos[id][DATOS_RESET] = SQL_ReadResult( Query, SQL_FieldNameToNum( Query, "reset" ) );
      			Estado[id] = REGISTRADO;
      			Menu_Spec(id); 
      		}
      		else 
      		{
      			Estado[id] = DESCONECTADO;
      			Menu_Spec(id);
      		}
      	}
      	case CUENTAS_TOTAL:
      	{
      	if( SQL_NumResults( Query ) )
		iCount = SQL_ReadResult( Query, 0 );
		}
	}
}
public ChequearCuenta(id){
    new Query[3500],Data[2];Data[0] = id;Data[1] = ChequearC
    formatex(Query,charsmax(Query),"SELECT * FROM `%s` WHERE nombre = ^"%s^"",TABLA,g_datos[id][DATOS_NOMBRE])
    SQL_ThreadQuery(g_hTuple,"DataHandler",Query,Data,2)
    return PLUGIN_HANDLED
}

public Total_Cuentas(id){
    new Query[3500],Data[2];Data[0] = id;Data[1] = CUENTAS_TOTAL
    formatex(Query,charsmax(Query),"SELECT COUNT(*) AS `total` FROM `%s`",TABLA)
    SQL_ThreadQuery(g_hTuple,"DataHandler",Query,Data,2)
    return PLUGIN_HANDLED
}
public Menu_Ingresar(id) {   
    new len[2048], menu 
    
    formatex(len, charsmax(len), "\yMenu De Espectador^n") 
    menu = menu_create(len, "handler_configsistem")
    
    menu_additem(menu, "\wIngresar a jugar", "1")
    menu_additem(menu, "\wVer mis estadisticas^n", "2")
    
    menu_setprop(menu, MPROP_EXITNAME, "\r[Salir]")
    menu_display(id, menu, 0)
}
public handler_configsistem(id, menu, item) {
    if(item==MENU_EXIT) return PLUGIN_HANDLED
    
    switch(item) 
    {
        case 0: {engclient_cmd( id, "jointeam", "5" );engclient_cmd( id, "joinclass", "5" );}
        case 1: Menu_Perfil(id)
   	}
    return PLUGIN_HANDLED
}
public TextMenu(msgid, dest, id)
{
    if( g_estado & (1<<id) )return PLUGIN_CONTINUE;
    static sMenuCode[ 33 ];get_msg_arg_string( 4, sMenuCode, charsmax( sMenuCode ) );
    if( containi( sMenuCode, "Team_Select" ) != -1 ) {ChequearCuenta( id );return PLUGIN_HANDLED;}
    return PLUGIN_CONTINUE;
}

public VGUIMenu2(msgid, dest, id)
{
    if( g_estado & (1<<id) ||  get_msg_arg_int( 1 ) != 2 ) return PLUGIN_CONTINUE;
    ChequearCuenta( id );return PLUGIN_HANDLED;
}
public guardar_datos( id ) 
{
    new szQuery[ 2500 ], iData[ 2 ];
    iData[ 0 ] = id;
    iData[ 1 ] = GUARDAR_DATOS;
    
    formatex( szQuery, charsmax( szQuery ), "UPDATE `%s` SET ultima=now(),asesinatos=%d,headshots=%d,muertes=%d,experiencia=%d,nivel=%d,reset=%d WHERE id='%d'",TABLA,
    	g_datos[id][DATOS_ASESINATOS],g_datos[id][DATOS_HEADSHOTS],g_datos[id][DATOS_MUERTES],
    	g_datos[id][DATOS_EXP],g_datos[id][DATOS_NIVEL],g_datos[id][DATOS_RESET],
    	g_datos[id][DATOS_ID]);

    SQL_ThreadQuery( g_hTuple, "DataHandler", szQuery, iData, 2 );
    set_task(0.4, "sqlLoadTop");
}

public CheckEXP(id, EXP,const motivo[])
{
	if(!EXP) return 0;
	
	if((g_datos[id][DATOS_EXP] + EXP) >= SiguienteNivel(MAX_LEVEL))
	{
		g_datos[id][DATOS_EXP] = SiguienteNivel(MAX_LEVEL)
		g_datos[id][DATOS_NIVEL] = MAX_LEVEL
		return 0;
	}

	g_datos[id][DATOS_EXP] += EXP

	while(g_datos[id][DATOS_EXP] >= SiguienteNivel(g_datos[id][DATOS_NIVEL]))
	{
		g_datos[id][DATOS_NIVEL]++
		g_datos[id][DATOS_EXP] = 0

		print_EasyChat(id, "%s has subido al nivel \g%d",TAG,g_datos[id][DATOS_NIVEL])
	}
	guardar_datos(id)
	
	return 1;
}
public Menu_Reset(id)
{
	
	new menu = menu_create("\yMenu Resetear Cuenta", "Menu_Reset_Cases")
	
	if (g_datos[id][DATOS_NIVEL] >= MAX_LEVEL)
		menu_additem(menu, "\y Resetear Cuenta", "1", 0);
	else
		menu_additem(menu, "\d Resetear Cuenta ", "1", 0);

	menu_setprop(menu, MPROP_EXITNAME, "Salir");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED;
}

public Menu_Reset_Cases(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		Menu_Perfil(id)
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	switch(item)
	{
		case 1:
		{
			if(g_datos[id][DATOS_NIVEL] < MAX_LEVEL)
			{
				print_EasyChat(id, "%s Para \tresetear \nnecesitas ser Nivel: \g%d",TAG,MAX_LEVEL)
				Menu_Reset(id)
			}
			else if (g_datos[id][DATOS_NIVEL] >= MAX_LEVEL)
			{
				g_datos[id][DATOS_NIVEL] = 1
				g_datos[id][DATOS_RESET]++
				print_EasyChat(id, "%s Acabas \tde resetear \nAhora tienes: \g%d \nResets",TAG,g_datos[id][DATOS_RESET])
				guardar_datos(id)
			}
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public sqlLoadTop()
{
    new Handle:sqlQuery
    new Handle:Query,Handle:Tuple
    static Error,szError[300]
    Query = SQL_MakeDbTuple(MYSQL_HOST,MYSQL_USER,MYSQL_PASS,MYSQL_DATEBASE)
    Tuple = SQL_Connect(Query,Error,szError,300)

    sqlQuery = SQL_PrepareQuery(Tuple, "SELECT nombre, nivel FROM %s ORDER BY nivel DESC LIMIT 15;",TABLA);
    
    if(!SQL_Execute(sqlQuery))
        checkError(sqlQuery, 1);
    else if(SQL_NumResults(sqlQuery))
    {
        g_top_menu = menu_create("\yTOP 15 - Niveles", "menu_Nothing");
        
        g_block_top_menu = 0;
        
        new sData[128];
        new sName[32];
        new sPosition[5];
        
        new iLevel;
        new iPosition;
        
        while(SQL_MoreResults(sqlQuery))
        {
            ++iPosition;
            
            SQL_ReadResult(sqlQuery, 0, sName, charsmax(sName));
            iLevel = SQL_ReadResult( sqlQuery, SQL_FieldNameToNum( sqlQuery, "nivel" ) );
            
            num_to_str(iPosition, sPosition, charsmax(sPosition));

            formatex(sData, charsmax(sData), "\r#%s \y- \w%s \y- \wNivel \r%d",sPosition, sName, iLevel);
            menu_addtext2( g_top_menu, sData);
                        
            SQL_NextRow(sqlQuery);
        }
        
        menu_setprop(g_top_menu, MPROP_NEXTNAME, "Siguiente");
        menu_setprop(g_top_menu, MPROP_BACKNAME, "Atrás");
        menu_setprop(g_top_menu, MPROP_EXITNAME, "Salir");
        
        SQL_FreeHandle(sqlQuery); 
    }
    else 
    {
        g_block_top_menu = 1;
        SQL_FreeHandle(sqlQuery);
    }
}
public checkError(const Handle:sqlQuery, const query_num)
{
    SQL_QueryError(sqlQuery, g_sql_error, charsmax(g_sql_error));
    
    log_to_file("error_sql.log", "- CONSULTA: %d - ERROR: %s", query_num, g_sql_error);
    
    SQL_FreeHandle(sqlQuery);
}

public clcmd_Top15(id)
{
    if(!is_user_connected(id))
        return PLUGIN_HANDLED;
    
    if(g_block_top_menu)
    {
        client_print(id, print_chat, "* El TOP15 está vacío!");
        return PLUGIN_HANDLED;
    }
    
    menu_display(id, g_top_menu);
    
    return PLUGIN_HANDLED;
}

public menu_Nothing(id, menuid, item)
{
    if(!is_user_connected(id) || item == MENU_EXIT)
        return PLUGIN_HANDLED;
    
    clcmd_Top15(id);
    return PLUGIN_HANDLED;
} 

stock print_EasyChat(const id, const input[], any:...) {
	new iCount = 1, iPlayers[32]
	
	static szMsg[191]
	vformat(szMsg, charsmax(szMsg), input, 3)
	
	replace_all(szMsg, 190, "\g", "^4") 
	replace_all(szMsg, 190, "\n", "^1")
	replace_all(szMsg, 190, "\t", "^3")
	
	if(id) iPlayers[0] = id
	
	else get_players(iPlayers, iCount, "ch")
	
	for (new i = 0; i < iCount; i++) {
		if (is_user_connected(iPlayers[i])) {
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, iPlayers[i])
			write_byte(iPlayers[i])
			write_string(szMsg)
			message_end()
		}
	}
}
