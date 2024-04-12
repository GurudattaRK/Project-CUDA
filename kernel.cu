#include<stdio.h>
#include<conio.h>
#include<stdlib.h>
#include<cuda_runtime.h>

#define CIPHER_BLOCK 128

// CUDA kernel
__global__ void supCUDA(char* key,char* initaddr,int itersize, int rounds ) 
{
    int id = (threadIdx.x) + (blockIdx.x * 32);
    
    unsigned long long int  hostaddr =(unsigned long long int)initaddr ;

    if(threadIdx.x == 0)
    printf("%d iter = %d : %llu\n",id,itersize,hostaddr);

    hostaddr = hostaddr + (id*128);
    // unsigned long long int addr = hostaddr + (id*itersize) ;
    char* thread_addr = (char*)hostaddr;
    unsigned char tic=32;
    while (rounds >0)
    {
        if(threadIdx.x == 0)
        printf("tid = %d : %llu\n",id,(unsigned long long int*)thread_addr);
        for(int i=0 ; i<128 ; i++)
        {
            thread_addr[i] = thread_addr[i]^key[i];
        } 
        thread_addr = thread_addr+itersize;
        rounds--;
    }
    
    
}


int main()
{
    // remove("1.txt");
    FILE* reader = fopen("1.txt","rb");
    FILE* writer = fopen("2.txt","wb");

    int blocks=2,warp_size =32;
    int rounds =4;

    int iter_size = blocks*warp_size*CIPHER_BLOCK;
    unsigned long long int total_size = blocks*warp_size*CIPHER_BLOCK*rounds;

    char* data = (char*)calloc(1,total_size);
    // memset(data,69,total_size);
    char key[130] = "qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,wuriov\0\0";

    // Allocate memory on the device
    char *CudaData, *CudaKey;

    
    data = (char*)calloc(1,total_size);

    fread(data, total_size,1,reader);

    printf("1\n");
    cudaMalloc((void**)&CudaData, total_size);
    // cudaMalloc((void**)&deviceOutput, BUF_SIZE);
    cudaMalloc((void**)&CudaKey, 129);
    printf("2\n");

    cudaMemcpy(CudaData, data, total_size, cudaMemcpyHostToDevice);
    cudaMemcpy(CudaKey, key, 128, cudaMemcpyHostToDevice);
    printf("3\n");

    supCUDA<<<2,32>>>(CudaKey,CudaData,iter_size,rounds);
    printf("4\n");

    cudaDeviceSynchronize();
    printf("5\n");


    cudaMemcpy(data, CudaData,  total_size, cudaMemcpyDeviceToHost);
    printf("%32767s\n",data);
    printf("6\n");

    cudaFree(CudaData);
    cudaFree(CudaKey);


    fwrite(data, total_size,1,writer);
    // fwrite(data,1,32768,writer);

    
    free(data);

    fclose(writer);
    fclose(reader);
    printf("7\n");


    return 0;
}