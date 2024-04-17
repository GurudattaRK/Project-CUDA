# Project-CUDA
#### Unleash the power of a thousand cores!
## About this project
GPUs are state of the art Co-processors that can be used for more than just graphics processing or training AI/ML models. With their massively parallel processing capabilities these systems significantly accelerate all kind of parallelizable tasks . Project-CUDA is built using CUDA which is a proprietary GPU architecture of NVIDIA, so this application can only be run on NVIDIA GPUs. This application can encrypt/decrypt any file at blazingly fast speeds by utilizing hundreds or even thousands of CUDA cores & threads of your CUDA capable GPU. Version or generation of GPU shouldn't be a problem as the application is built to assess all available graphics card resources, GPU architecture & generation & dynamically allocating and managing RAM, VRAM & all CUDA cores & threads during Run-time. Application can dynamically scale its compute capabilities according to available hardware and system resources during execution.

## System requirements:
1. Nvidia GPU capable of CUDA (check online if your GPU supports CUDA)
2. Windows 10/11 64-bit
3. Some systems might have to install CUDA toolkit version 12 to run this

## Running the applicaiton:
1. Download & unzip "Project-CUDA.zip" 
2. Run the Project-CUDA.exe

## Warning
Do not move or change contents of any file in "_internal" in the zip folder. It contains all the libraries, dependencies & backend CUDA kernel.
