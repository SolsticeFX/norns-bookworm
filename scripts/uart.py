import sys
import serial
import time
if __name__ == '__main__':
    # if connected via USB cable
    #ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1) #9600 is baud rate(must be same with that of NodeMCU)
    # if connected via serial Pin(RX, TX)
    #ser = serial.Serial('/dev/ttyAMA0', 115200, timeout=1) #9600 is baud rate(must>
    #ser.flush()
    ser2 = serial.Serial('/dev/ttyAMA0', 38400, timeout=10) #9600 is baud rate(must be same with that of NodeMCU)
    #ser2.flush()
while True:
       # string = str(sys.argv[1])
        string = input("enter string:") #input from user
        string = string #"\n" for line seperation
        string = string.encode('utf_8')
        #ser.write(string) #sending over UART
        ser2.write(string)
        line = ser2.readline().decode('utf-8').rstrip()
        #line = ser2.readline().decode('iso-8859-1')
        print("received: ",line)
        time.sleep(0.1) #delay of 1 second




