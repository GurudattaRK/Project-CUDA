from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QLineEdit, QPushButton, QVBoxLayout, QHBoxLayout
from PyQt5.QtGui import QFont, QIcon, QMovie, QPixmap
from tkinter import filedialog
from multiprocessing import *
from PyQt5.QtCore import Qt
from ctypes import *
from time import *
import subprocess
import threading
import hashlib
import msvcrt
import sys
import os

def resource_path(relative_path):
    #Get absolute path to resource, works for dev and for PyInstaller
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")

    return os.path.join(base_path, relative_path)


def openfile1(result_list,label2):
    filepath1=filedialog.askopenfilename()
    label2.setText('File selected: '+str(filepath1))
    result_list[0]=str(filepath1)


def aux(password, mode, result_list, label4, label5, label6, main_window):

    label4.hide()
    #main_window.show_finished_image(69)
    label5.setText("Processing your file...")
    label6.setText("")
    

    hashv= hashlib.sha3_512(str(password).encode("utf-8"))
    c = hashv.digest()
    hashv= hashlib.sha3_512(str(c).encode("utf-8"))
    d = hashv.digest()
    c = c + d
    keys = c.hex()
    
    

    inputfile = str(result_list[0])

    if(mode == 0):
        output= inputfile + ".lock"
    else:
        # Remove the extension from the path
        #output = os.path.splitext(inputf)[0]
        # Check if the extension is "lock" and remove it
        if inputfile.endswith(".lock"):
            output = inputfile[:-5]
            output_name = os.path.splitext(output)[0]
            ouput_ext=os.path.splitext(output)[1]
            output=output_name + "_unlocked" + ouput_ext
        else:
            output = inputfile
            output_name = os.path.splitext(output)[0]
            ouput_ext=os.path.splitext(output)[1]
            output=output_name + "_unlocked" + ouput_ext

    outputfile = open(output, "wb")
    outputfile.close()

    file_stat = os.stat(inputfile)
    filesize= file_stat.st_size
    OGfilesize = filesize



    start= time()
    ffi_file = "FFI_data.txt"
    outputfile = open(ffi_file, "w")
    outputfile.write(keys)
    outputfile.write("\n")
    outputfile.write(inputfile)
    outputfile.write("\n")
    outputfile.write(output)
    outputfile.write("\n")
    outputfile.write(str(filesize))
    outputfile.write("\n")
    outputfile.write(str(mode))
    outputfile.close()

    file_stat = os.stat(ffi_file)
    trash_size = file_stat.st_size


    executable_path = "CUDA_backend.exe"  # Replace with actual path
    arguments = [ffi_file]  # Replace with your input values

    subprocess.run([executable_path, *arguments])

    ffi_file = "FFI_data.txt"
    trash = b'00'*trash_size
    outputfile = open(ffi_file, "wb")
    outputfile.write(trash)
    outputfile.close()
    os.remove(ffi_file)
    
    
    end_time = time()
    execution_time = end_time - start
    

    if(mode ==0):
        main_window.show_finished_image(0)
        msg1 ="Encrypted file's location:\n"+str(output)
        msg2 ="Encrypted "+ str(OGfilesize) +" bytes in "+str(execution_time) + " seconds"

    else:
        main_window.show_finished_image(1)
        msg1 ="Decrypted file's location:\n"+str(output)
        msg2 ="Decrypted "+ str(OGfilesize) +" bytes in "+str(execution_time) + " seconds"

    label5.setText(msg1)
    label5.setAlignment(Qt.AlignCenter)
    label6.setText(msg2)

    return


class MyWidget(QWidget):

    def start_aux_thread(self,mode):
        self.loading_movie = QMovie(resource_path('loading.gif'))
        self.loading_label = QLabel(self)
        self.loading_label.setMovie(self.loading_movie)
        self.loading_label.setAlignment(Qt.AlignCenter)
        self.loading_movie.start()
        self.label4.setText("")  # Clear any previous messages
        self.layout().insertWidget(8, self.loading_label)  # Insert the loading label just before label4

        password = self.password_field.text()
        self.password_field.clear()

        thread = threading.Thread(target=aux, args=(password, mode, result_list, self.label4, self.label5, self.label6, self))
        thread.start()
    
    def show_finished_image(self,mode):
        # Hide the loading label
        self.loading_label.hide()
        self.label4.show()
        finished_image_path1 = resource_path('locked_file.png')

        finished_image_path2 = resource_path('unlocked_file.png')

        # Load and set the finished image
        if(mode == 0):
            pixmap = QPixmap(finished_image_path1)

        else:
            pixmap = QPixmap(finished_image_path2)
        
        self.label4.setText("")  # Clear any previous messages
        self.label4.setPixmap(pixmap)
        self.label4.setAlignment(Qt.AlignCenter)

    def toggle_password_visibility(self):
        if self.password_field.echoMode() == QLineEdit.Password:
            self.password_field.setEchoMode(QLineEdit.Normal)
        else:
            self.password_field.setEchoMode(QLineEdit.Password)


    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):

        try:
            icon_path= resource_path('nvidialock.ico')
            self.setWindowIcon(QIcon(icon_path))
        except:
            print("Icon file named nvidialock.ico not found")

        label1 = QLabel('Select the file you want to Encrypt/Decrypt')
        label1.setStyleSheet("color: #02013D; font-weight: bold;")
        label1.setFont(QFont("Calibri", 18))

        button1 = QPushButton('Select file here')
        button1.setStyleSheet("background-color: #2510c7; color: white; padding: 10px; border-radius: 5px;")
        button1.setFont(QFont("Calibri", 15, QFont.Bold))
        button1.clicked.connect(lambda:openfile1(result_list, self.label2))

        executable_path = "corecount.exe"
        try:
            output = subprocess.check_output(executable_path, universal_newlines=True)
        except subprocess.CalledProcessError as e:
            count=e.returncode

        self.label2 = QLabel('')
        self.label2.setStyleSheet("color: #444444; font-weight: bold;")
        self.label2.setText('Tip: Choose a file bigger than '+str(count*5*128) + ' bytes to utilize full strength of your GPU')


        label3 = QLabel('Enter your password:')
        label3.setStyleSheet("color: #02013D; font-weight: bold;")
        label3.setFont(QFont("Calibri", 15))
        
        self.label4 = QLabel('')
        self.label4.setStyleSheet("color: #222222; font-weight: bold;")
        self.label4.setFont(QFont("Calibri", 14))

        self.label5 = QLabel('')
        self.label5.setStyleSheet("color: #444444; font-weight: bold;")
        self.label5.setFont(QFont("Calibri", 14))

        self.label6 = QLabel('')
        self.label6.setStyleSheet("color: #666666; font-weight: bold;")
        self.label6.setFont(QFont("Calibri", 12))

        self.password_field = QLineEdit()
        self.password_field.setEchoMode(QLineEdit.Password)  # Set the echo mode to Password for masked input
        self.password_field.setStyleSheet("background-color: #F0F0F0; border: 1px solid #BFBFBF; padding: 10px; border-radius: 5px;")
        self.password_field.setFont(QFont("Calibri", 12))

        self.show_password_button = QPushButton()
        eye_con = resource_path('eye_con.png')
        self.show_password_button.setIcon(QIcon(eye_con))
        self.show_password_button.clicked.connect(self.toggle_password_visibility)
        
        
        button2 = QPushButton('Encrypt')
        button2.setStyleSheet("background-color: #77b801; color: white; padding: 10px; border-radius: 5px;")
        button2.setFont(QFont("Calibri", 15, QFont.Bold))
        button2.clicked.connect(lambda _: self.start_aux_thread(0))

        button3 = QPushButton('Decrypt')
        button3.setStyleSheet("background-color: #c90202; color: white; padding: 10px; border-radius: 5px;")
        button3.setFont(QFont("Calibri", 15, QFont.Bold))
        button3.clicked.connect(lambda _: self.start_aux_thread(1))

        vbox = QVBoxLayout()
        hbox = QHBoxLayout()
        hbox2 = QHBoxLayout()

        vbox.addWidget(label1)
        vbox.addWidget(button1)
        vbox.addWidget(self.label2)
        vbox.addWidget(label3)
        vbox.addLayout(hbox)
        hbox.addWidget(self.password_field)
        hbox.addWidget(self.show_password_button)
        vbox.addLayout(hbox2)

        hbox2.addWidget(button2)
        hbox2.addWidget(button3)
        vbox.addWidget(self.label4)
        vbox.addWidget(self.label5)
        vbox.addWidget(self.label6)
        vbox.setSpacing(20)
        vbox.setContentsMargins(20, 20, 20, 20)

        self.setLayout(vbox)


if __name__ == '__main__':
    freeze_support()
    global result_list
    result_list=[2]
    app = QApplication(sys.argv)
    widget = MyWidget()
    widget.resize(400, 300)  # Set the width to 400 pixels and height to 300 pixels
    widget.setWindowTitle("Project-CUDA")
    widget.show()
    sys.exit(app.exec_())

#(Get-FileHash -Path "filename" -Algorithm SHA512).Hash


