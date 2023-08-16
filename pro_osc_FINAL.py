from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import BlockingOSCUDPServer
from escpos.printer import Usb
import os
from unidecode import unidecode
import time

# Specify the USB vendor ID, product ID, and endpoint addresses
vendor_id = 0x0456
product_id = 0x0808
in_endpoint = 0x81
out_endpoint = 0x03

# Connect to the USB printer
p = Usb(vendor_id, product_id, 0, in_endpoint, out_endpoint)

def remove_special_chars(s):
  cleaned = s.replace("¿","").replace("¡","")
  return unidecode(cleaned)
def get_max_chars_per_line():
    try:
        _,columns = os.get_terminal_size()
        return columns
    except e:
        print("error")
        print(e)
max_chars = get_max_chars_per_line()
max_chars=46


def center_pad_string(s):
    n = 46    # max chars
    padding = n-len(s)
    left_padding = padding // 2
    right_padding = padding - left_padding
    
    result = ' ' * left_padding + s + ' ' * right_padding 

    return result

def get_slope_char(prev_val,current_val):
    slope = current_val - prev_val
    #print(slope)
    slope_char = "|"
    if slope < 0:
        slope_char = "/"
    elif slope > 0:
        slope_char = "\\"
    return slope_char,slope


def map_value(value, xorig,yorig,xnew,ynew):
    normalized = (int(value)-xorig)/(yorig-ynew)
    mapped = xnew+normalized*(ynew-xnew)
    return int(mapped)
    
plot_string=""
prev_value=0

edades_contempladas = 0
old_slope_char="-"
def render_line(value,char):
    line = "-" *max_chars
    new_line = line[:value]+char+line[value+1:]
    new_line = new_line[:46]
    return new_line+"\n"

def print_handler(address, *args):
    # el dato se ve así:
    # /datos: ('368', '23', 'MUJER', '0', 'PRINCIPAL', 'Entre Ríos', '7', 'ESTRANGULAMIENTO', '2013-02-11') None

    edad=args[1]
    global prev_value

    global edades_contempladas
    new_value = map_value(edad,0,99,0, max_chars)
    #print(str(new_value )+ ' <nv vs totl<' +str( edades_contempladas))
    poem_file = "text.txt"
    with open(poem_file, 'r') as file:
    	lines = [line.strip() for line in file if line.strip()]
    lines = " ".join(lines)
    lines = remove_special_chars(lines)
    orig_len_lines = len(lines)  
    to_print = "" 
    #lines = center_pad_string(lines,max_chars)
    if edades_contempladas <= new_value:
       #print("caso edades_contempladas < new_value")
       to_print = center_pad_string(lines[edades_contempladas:new_value])+'\n'
    else:
       #print("caso edades_contempladas > new_value")
       to_print = center_pad_string(lines[edades_contempladas:new_value+edades_contempladas])+'\n'
    
    edades_contempladas += new_value
    if edades_contempladas >= orig_len_lines:
       #print("reset")
       edades_contempladas=0
    time.sleep(1.5)
    print(to_print)
    print(p.text(str(to_print)))
    #debug print vvvvvvvvvvvv
    #print(f"{address}: {args}", to_print )
    #print(lines)
    #print(f"{address}: {args}", p.text(line ))
    #print(f"{address}: {args}", p.text(line ))
    #print(f"{address}: {args}", p.text(line ))
    #print(p.text("\n"))   
    # args 9-upla
    """ pseudocodigo
    sea MAX_CHARS el ancho max de la impresora
    print("-" * max_chars ) #<-- eq a imprimir una linea entera con guion medio
    sea edad=args[1] #edad es un dato tq mientras mas chico es, mas grande es el dibujoi hecho en processing
    new_value = map(0, MAX_CHARS, 0, 99)
    to_print = "-" * MAX_CHARS
    to_print[new_value] = "/" #<- tener en cuenta el anterior para saber si es / o \
    print(to_print)
    """
    #print(f"{address}: {args}", p.text(args[0]+args[1]+args[2]))#p.image("img1.png"))

    #print(f"{address}: {args}", p.text("canto el temblor de mis huesoss"))




def default_handler(address, *args):
    print("EL OTRO")
    print(f"DEFAULT {address}: {args}")


dispatcher = Dispatcher()
dispatcher.map("/datos", print_handler)
dispatcher.set_default_handler(default_handler)

ip = "127.0.0.255"
port = 9998

server = BlockingOSCUDPServer((ip, port), dispatcher)
server.serve_forever()  # Blocks forever
