// CNT
// Solo instalar librerias OSC
import oscP5.*;
import netP5.*;
import java.util.List;
import java.util.Arrays;
OscP5 oscP5;
NetAddress myRemoteLocation1;
NetAddress myRemoteLocation2;
String[] filasRegistro;
// Solo las fechas de los hechos
String[] fechasHechos;
// Funciona como puntero
// Contiene todos los dias
String[] fechasRango;
// Dataset llamadas
String[] registroLlamadas;
// Lista para chequear fechas y enviar pulso
List listaFechasHechos;
// --------------------------------------
int EDAD_MAX = 0;
int FILA_Y = 0;
// Contadores llamadas -------------------
int CONTADOR_LLAMADA = 0;
// Contadores Hechos -------------------
int CONTADOR_DIA = 0;
int CONTADOR_HECHO = 0;
int FRECUENCIA_HECHO = 40;
// -------------------------------------
// Indices (posicion columna) del archivo
static int IDX_CASO = 0;
static int IDX_EDAD = 1;
// Genero
// 0 - Mujer
// 1 - Hombre
// 2 - Transgenero
// 3 - no especificado
//static int IDX_GENERO_NOMBRE = 2;
//static int IDX_GENERO = 3;
static int IDX_PROVINCIA = 6;

// Grafico ------------------------------
float intervaloLineas = 10;
int numLineas;
PVector[] posPrevLineas;
float[] posVelLineas;
float[] DRAW_X;
// Textos -----------------------------
int DRAW_TEXTO_Y = 0;
// -------------------------------------
// Variables globales para grafico
int[] G_COLOR = new int[24]; // x provincia
int[] G_EDAD = new int[24]; // x provincia
float[] MOVIMIENTOS = new float[24]; // x provincia
float[] DESPLAZAMIENTOS = new float[24]; // x provincia
float G_HORA_LLAMADA = 0;
int G_PROVINCIA = -1;
// -------------------------------------
void settings() {
    //fullScreen();
    size(1280, 720);
}
void setup() {
    // VELOCIDAD DEL DIBUJO -------------------------------
    // Velocidad del void draw()
    frameRate(15); // frames por segundo
    // -----------------------------------------------------

    // NEt OSC ---------------------------------------------
    oscP5 = new OscP5(this, 12000);
  //myRemoteLocation1 = new NetAddress("192.168.0.30", 9997);
  myRemoteLocation2 = new NetAddress("127.0.0.255", 9998);
  myRemoteLocation1 = new NetAddress("127.0.0.255", 12001);
    // ----------------------------------------------------
    // Carga ficheros -------------------------------------
    //
    filasRegistro = loadStrings("registro_hechos.csv");
    filasRegistro = subset(filasRegistro, 1); // Quitar nombres de las columnas
    //
    fechasHechos = loadStrings("fechas_hechos.txt");
    //
    registroLlamadas = loadStrings("registro_llamadas.csv");
    registroLlamadas = subset(registroLlamadas, 1); // Quitar nombres de las columnas
    // Se utiliza para activar pulso -> si listaFechasHechos existe en fechasRango
    listaFechasHechos = Arrays.asList(fechasHechos);
    // Desde 01/01/2013 al 13/09/2019
    fechasRango = loadStrings("fechas_rango.txt");
    // Busca el numero máximo de edad ------------------------
    for (int i = 0; i< filasRegistro.length; i++) {
        String[] cols = filasRegistro[i].split(",");
        if (int(cols[1])<110 && int(cols[1]) > EDAD_MAX) {
            EDAD_MAX = int(cols[1]);
        }
    }
    // ----------------------------------------------------
    // parametros grafico hechos --------------------------
    numLineas = 24; // 24 provincias
    intervaloLineas = height / numLineas * 0.8; // alto de la fila segun -> alto total / cant provincias
    // Almacena (x,y) previo para dibujar linea -> line(prev.x,prev.y,x,y)
    posPrevLineas = new PVector[numLineas];
    // almacena velocidad x lina (provincia)
    posVelLineas = new float[numLineas];
    // Controla el eje X por cada provincia
    DRAW_X = new float[numLineas];
    // Inicialización
    for (int i = 0; i < numLineas; i++) {
        posPrevLineas[i] = new PVector(0, i * intervaloLineas);
        posVelLineas[i] = 1;
        DRAW_X[i] = 0;
        G_EDAD[i] = 999;
        //G_COLOR[i] = color(255);
        MOVIMIENTOS[i] = 0;
        DESPLAZAMIENTOS[i] = 0;
    }
    background(0);
    noStroke();
}
void draw() {

    if (frameCount % FRECUENCIA_HECHO == 0) { // maneja velocidad
        String fechaActual = fechasRango[CONTADOR_DIA%fechasRango.length];

        // Ingresa solo si hay un hecho ---------------
        if (listaFechasHechos.contains(fechaActual)) {
            // Index para recorrer el registro
            int indexFilaRegistro = CONTADOR_HECHO % filasRegistro.length;
            // Fila actual del registro
            String[] fila = filasRegistro[indexFilaRegistro].split(",");
            G_PROVINCIA = int(fila[IDX_PROVINCIA]);
            G_EDAD[G_PROVINCIA%numLineas] = int(fila[IDX_EDAD]);
            // **********************************************************
            // Envio pulso OSC ******************************************
            // Dataset --------------------------------------------------------------------------------------
            // 0       1       2         3         4          5            6               7            8
            // CASO    EDAD    GENERO    GENERO    VINCULO    PROVINCIA    ID PROVINCIA    MODALIDAD    FECHA
            // ----------------------------------------------------------------------------------------------
            sendPulso(fila); // -> ver ids arriba
            // **********************************************************
            // Solo incrementa cuando hay un hecho
            CONTADOR_HECHO++;
        }
        // Contador dias del rango total
        CONTADOR_DIA++;
    }
    // LLAMADAS
    if (frameCount % int(random(2, 50))== 0) {
        // ID contador llamada
        int IDX = CONTADOR_LLAMADA % registroLlamadas.length;
        fill(255, random(5, 60));
        // intervalo proxima linea en Y
        int salto = int(random(10, 100));
        // Random movimiento en x
        int desplazamiento_x = int(random(-50, 50));
        textAlign(CENTER, CENTER);
        textSize(random(5, 40));
        text(registroLlamadas[IDX], width/2 + desplazamiento_x, DRAW_TEXTO_Y);
        // **********************************************************
        // Envio pulso OSC ******************************************
        // caso_id    llamante_descripcion    llamante_genero    llamante_vinculo_ninios_presentes    violencia_tipo    victima_edad    victima_rango_etario    victima_genero    victima_cantidad    agresor_cantidad    agresor_genero    agresor_relacion_victima    llamado_derivacion    llamado_fecha    llamado_hora    Hora
        // sendPulso(registroLlamadas);
        // **********************************************************
        String[] columnas = registroLlamadas[IDX].split(",");
        G_HORA_LLAMADA = int(columnas[columnas.length-1]);
        CONTADOR_LLAMADA++;
        // GRAFICO LLAMADAS
        DRAW_TEXTO_Y+=salto;
        if (DRAW_TEXTO_Y>height) {
            DRAW_TEXTO_Y = 0;
        }
        // Alarga hecho x llamada -------------
        float velocidad = 1.0 - (G_HORA_LLAMADA / 24 * 0.3);
        posVelLineas[int(random(0, numLineas))] = velocidad;
    }
    if (frameCount % 2 == 0) {
        // Reduce el rango de amplitud
        for (int i = 0; i < numLineas; i++) {
            G_EDAD[i] += map(sin(frameCount*10), -1, 1, -1, 3);
        }
    }
    // -------------------------------------------------------
    // GRAFICO -----------------------------------------------
    // -------------------------------------------------------
    for (int i = 0; i< numLineas; i++) {
        // Random filas llamados
        // Utiliza la hora para dar grosor a la linea
        String col_llam = registroLlamadas[floor(random(registroLlamadas.length))];
        String[] columnas = col_llam.split(",");
        float sw = float(columnas[columnas.length-1]) / 24 + 0.6;
        strokeWeight(sw);
        // NUM LINEA = ID PROVINCIA
        // Eje Y
        int DRAW_Y = int(i * intervaloLineas + intervaloLineas + (height*0.08));
        
        // Color de la linea
        stroke(255);

        // REFERIDO A EDAD -> Amplitud -> Y
        float MAX_AMP = 200;
        MOVIMIENTOS[i] = constrain(map(G_EDAD[i], 0, EDAD_MAX, MAX_AMP, 1), 0, EDAD_MAX);

        // Desplazamiento eje Y
        float CUR_AMP = MOVIMIENTOS[i];
        // Modular para que no sea siempre un release lineal
        float modularForma = map(sin(frameCount*random(0.005, 0.2)), -1, 1, CUR_AMP*0.2, CUR_AMP);
        DESPLAZAMIENTOS[i] = constrain(map(sin(frameCount*4), -1, 1, -MOVIMIENTOS[i], MOVIMIENTOS[i]), -modularForma, modularForma);

        // Colorea
        float alpha = map(CUR_AMP, 0, MAX_AMP, 255, 20);
        stroke(255, alpha);
        if (i == 17) {
            // Si es san juan -> rojo
            stroke(255, 0, 0);
        }
        // Dibujo
        //if (frameCount%10 == 0 && abs(CUR_AMP)>20) {
        //    float diam = random(2, 6);
        //    ellipse(posPrevLineas[i].x, posPrevLineas[i].y, diam, diam);
        //}
        line(posPrevLineas[i].x, posPrevLineas[i].y, DRAW_X[i], DRAW_Y + DESPLAZAMIENTOS[i]);
        // Almacena el punto previo de la linea
        posPrevLineas[i].set(DRAW_X[i], DRAW_Y + DESPLAZAMIENTOS[i]);

        // Suma velocidad a la posicion X
        DRAW_X[i] += posVelLineas[i];

        // Si X es mayor al ancho, volver a 0 la posicion previa
        if (DRAW_X[i] >= width) {
            DRAW_X[i] = 0;
            posPrevLineas[i].set(0, i * intervaloLineas);
        }
    }
    if (frameCount % 20 == 0) {
        noStroke();
        fill(0, 20);
        rect(0, 0, width, height);
    }
}

void sendPulso(String[] s) {
    //printArray(s);
    OscMessage myMessage = new OscMessage("/datos");

    myMessage.add(s); /* add an int to the osc message */

    /* send the message */
    oscP5.send(myMessage, myRemoteLocation1);
    oscP5.send(myMessage, myRemoteLocation2);
}
void oscEvent(OscMessage theOscMessage) {
    /* print the address pattern and the typetag of the received OscMessage */
    print("### received an osc message.");
    print(" addrpattern: "+theOscMessage.addrPattern());
    println(" typetag: "+theOscMessage.typetag());
}
