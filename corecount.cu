#include<cuda_runtime.h>

int main()
{
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp,0);
    unsigned long long int blocks, threads;

    blocks = deviceProp.multiProcessorCount;
    threads =deviceProp.warpSize;
    return threads*blocks;
}