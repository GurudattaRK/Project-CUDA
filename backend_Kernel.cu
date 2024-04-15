#include<stdio.h>
#include<conio.h>
#include<stdlib.h>
#include<cuda_runtime.h>

__global__ void supCUDA(char* key,char* initaddr,int itersize, int rounds ) 
{
    int id = (threadIdx.x) + (blockIdx.x * 32);
    
    unsigned long long int  hostaddr =(unsigned long long int)initaddr ;

    hostaddr = hostaddr + (id*128);
    // unsigned long long int addr = hostaddr + (id*itersize) ;
    char* thread_addr = (char*)hostaddr;

    // if(threadIdx.x == 0 && blockIdx.x == 0)4
    //     printf("tid = %d : %llu\n",id,(unsigned long long int*)thread_addr);

    while (rounds >0)
    {
        //ENCRYPTION BEGINS HERE (128 bytes from thread_addr with 128 bytes of key)  
        for(int i=0 ; i<128 ; i++)
        {
            thread_addr[i] = thread_addr[i]^key[i];
        } 
        //ENCRYPTION ENDS HERE
        thread_addr = thread_addr+itersize;
        rounds--;
    }
    
}

void sequentiel(char* key,char* data,int rounds)
{
    // unsigned long long int end = rounds *128;
    while(rounds>0 || rounds !=0)
    {
        for(int i=0; i<128;i++)
        {
            data[i]= data[i] ^ key[i];
        }
        data = data +128;
        rounds -- ;
    }

}

int main(int argc, char *argv[])
{

    char* argt =  argv[1];
    printf("\nArguement 1:%s\n",argt);
    FILE* tempfile = fopen(argt,"r");
    char line[257];
    char *lines[5]; // Array to store pointers to each line string
    int line_count = 0;

    // Read and store lines
    while (fgets(line, 257, tempfile) != NULL && line_count < 5) 
    {
        // Remove the newline character at the end of the line
        line[strcspn(line, "\n")] = '\0';

        // Skip empty lines
        if (strlen(line) == 0) {
            continue;
        }

        // Allocate memory for the line string and copy the line
        lines[line_count] = (char*)malloc((strlen(line) + 1) * sizeof(char));
        strcpy(lines[line_count], line);
        line_count++;
    }

    fclose(tempfile);


    unsigned long long int temp,residue,cuda_malloc_size,filesize,iter_size,max_free,available_mem,residue_offset,kernel_rounds=0;
    long long int rounds=0;
    char *CudaData, *CudaKey ,*inputfile, *outputfile,*size,*mode,*random;

    
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp,0);

    inputfile = lines[1];
    outputfile = lines[2];
    size = lines[3];
    mode = lines[4];

    FILE *reader = fopen(inputfile,"rb");
    FILE* writer = fopen(outputfile,"wb");

    int blocks =4,threads=32;
    blocks = deviceProp.multiProcessorCount;
    threads =deviceProp.warpSize;

    filesize  = strtoull(size,&random,10);
    
    cudaMemGetInfo(&available_mem,&temp);
    char *key = lines[0] ;

    printf("inputfile :%s\n",inputfile);
    printf("outputfile :%s\n",outputfile);
    printf("key :%s\n",key);
    printf("size :%llu\n",filesize);
    printf("mode :%s\n",mode);
    printf("============================\n");


    cudaMalloc((void**)&CudaKey, 129);
    cudaMemcpy(CudaKey, key, 128, cudaMemcpyHostToDevice);

    iter_size =blocks*threads*128 ;// (deviceProp.multiProcessorCount*deviceProp.warpSize*128);
    residue = available_mem % iter_size;
    max_free = available_mem-residue;
    // unsigned long long int total = total_bytes;

    printf("\nfree mem:  %llu",available_mem);
    printf("\nmaxfree:  %llu",max_free);
    printf("\nitersize:  %llu",iter_size);
    printf("\nprocessors:  %d",blocks);
    printf("\nwarp size:  %d",threads);
    printf("\n=====================\n");

    char *hostptr,*hostptrcpy;

    hostptr = (char*)malloc(filesize);
    fread(hostptr, filesize,1,reader);

    hostptrcpy = hostptr;

    residue = 0;

                                        printf("*1\n");

    if(filesize>max_free)
    {
        cuda_malloc_size=max_free;
        rounds = filesize / max_free;
        residue = filesize % max_free;
        residue_offset = rounds * max_free;
        kernel_rounds = max_free / iter_size;
        // printf("\nfull rounds: %lld\n",rounds);
                                        printf("*2\n");

        cudaMalloc((void**)&CudaData, cuda_malloc_size);

        while(rounds>0 || rounds != 0)
        {
                                        printf("*3\n");

            cudaMemcpy(CudaData,hostptrcpy,cuda_malloc_size,cudaMemcpyHostToDevice);
            //Launch CUDA kernel here
            supCUDA<<<blocks,threads>>>(CudaKey,CudaData,iter_size,kernel_rounds);
            cudaDeviceSynchronize();
                                        printf("*4\n");

            printf("Case1 heavy kernel launched\n");
            cudaMemcpy(hostptrcpy,CudaData,cuda_malloc_size,cudaMemcpyDeviceToHost);
                                        printf("*5\n");

            hostptrcpy = hostptrcpy + max_free;

            rounds--;
            printf("round:%llu\n",rounds);


        }
        cudaFree(CudaData);

                                        printf("*6\n");


    }
    else
    {
        rounds=0; 
                                        printf("*7\n");

        if(filesize <= iter_size)
        {
            residue = filesize;
            residue_offset = 0;
            kernel_rounds = 0;
                                        printf("*8\n");

        }
        else
        {
                                        printf("*9\n");

            temp =  filesize/iter_size;
            cuda_malloc_size = temp * iter_size;
            residue = filesize - cuda_malloc_size;
            residue_offset = cuda_malloc_size;
            kernel_rounds = temp ;

            cudaMalloc((void**)&CudaData, cuda_malloc_size);

            cudaMemcpy(CudaData,hostptrcpy,cuda_malloc_size,cudaMemcpyHostToDevice);
            //Launch CUDA kernel here
                                        printf("*A\n");

            supCUDA<<<blocks,threads>>>(CudaKey,CudaData,iter_size,kernel_rounds);
            cudaDeviceSynchronize();

            printf("Case2 mid kernel launched\n");
            cudaMemcpy(hostptrcpy,CudaData,cuda_malloc_size,cudaMemcpyDeviceToHost);
            cudaFree(CudaData);
                                        printf("*B\n");

        }
        
    }

    printf("\n=====================\n");

    if(residue!=0)
    {
        printf("\nresidue:%lld\n",residue);

        if(residue >= iter_size*10)
        {
            temp =  residue/iter_size;
            cuda_malloc_size = temp * iter_size;
            residue = residue - cuda_malloc_size;
            residue_offset = cuda_malloc_size;
            kernel_rounds = temp ;
                                        printf("*C\n");

            //Launch CUDA kernel here
            cudaMalloc((void**)&CudaData, cuda_malloc_size);

            cudaMemcpy(CudaData,hostptrcpy,cuda_malloc_size,cudaMemcpyHostToDevice);
            //Launch CUDA kernel here
            supCUDA<<<blocks,threads>>>(CudaKey,CudaData,iter_size,kernel_rounds);
            cudaDeviceSynchronize();
            printf("Case3 mid kernel launched\n");
            cudaMemcpy(hostptrcpy,CudaData,cuda_malloc_size,cudaMemcpyDeviceToHost);
                                        printf("*D\n");

            cudaFree(CudaData);
            hostptrcpy = hostptrcpy + residue_offset;
        }
        if(residue > 0 )
        {
                                        printf("*E\n");

            if((residue%128)==0)
            {
                rounds = residue / 128;

            }
            else
            {
                temp = residue%128 ;
                residue = residue + (128-temp);
                rounds = residue/128 ;
            }
            // printf("\nmid rounds:%lld",rounds);


            hostptrcpy= hostptr + residue_offset;

            printf("\n=====================\n");
            printf("residue:%lld\n",residue);
            printf("Case4 light sequential execution\n");
            printf("Sequential rounds: %lld\n",rounds);
            
            sequentiel(key,hostptrcpy,rounds);
            //Launch normal kernel here
            
        }

    }
    
    // cudaMalloc((void**)&cudaptr,cuda_malloc_size);


    // cudaMemcpy(cudaptr,hostptrcpy,cuda_malloc_size,cudaMemcpyHostToDevice);

    // printf("\n===============\n1:  %llu",available_mem);
    // printf("\n2:  %llu\n",max_free);
    // printf("3:  %llu\n",max_free/iter_size);

    // supCUDA<<<4,1024>>>(x, y);
    // cudaDeviceSynchronize();
    // cudaMemcpy(hostptrcpy,cudaptr,cuda_malloc_size,cudaMemcpyDeviceToDevice);


    // cudaFree(cudaptr);
    
    // cudaFree(CudaData);
    cudaFree(CudaKey);

    fwrite(hostptr, filesize,1,writer);

    fclose(writer);
    fclose(reader);

    for (int i = 0; i < line_count; i++) 
    {
        // printf("Line %d: %s\n", i, lines[i]);
        free(lines[i]);
    }

    free(hostptr);
    // // printf("\n%s",deviceProp.name);
    // printf("\nProcessors: %d",deviceProp.multiProcessorCount);
    // printf("\nWarp: %d",deviceProp.warpSize);
    // printf("\nIteration size: %d",deviceProp.multiProcessorCount*deviceProp.warpSize*128);

    return 0;
}
