#include <nvrtc.h>
#include <cuda_runtime.h>
#include <cuda.h>
#include <cstdio>

#define BUF_SIZE 1073741824

// CUDA kernel
__global__ void supCUDA(char* key, char* input) {
    int x = (threadIdx.x * 128) + (blockIdx.x * 32 * 128);
    for (int j = 0; j < 32768; j++) {
        for (int i = 0; i < 128; i++) {
            input[x + i] = input[x + i] ^ key[i];
        }
        x = x + 32768;
    }
}

int main() 
{
    
    // Allocate memory on the host for input and output data
    char* hostInput = (char*)malloc(BUF_SIZE);
    // char* hostOutput = (char*)malloc(BUF_SIZE);
    char key[130] = "qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,wuriov\0\0";
    
    clock_t begin,end;
    begin = clock();
    double time_spent;

    FILE* reader = fopen("1","rb");
    FILE* writer = fopen("1.CUDAlock","wb");

    fread(hostInput,BUF_SIZE,1,reader);


    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp,0);
    unsigned long long int freemem,totalmem;
    cudaMemGetInfo(&freemem,&totalmem);

    const char* cudaSourceCode = R"(
        extern "C" __global__ void supCUDA(char* key, char* input) {
            int x = (threadIdx.x * 128) + (blockIdx.x * 32 * 128);
            for (int j = 0; j < 32768; j++) {
                for (int i = 0; i < 128; i++) {
                    input[x + i] = input[x + i] ^ key[i];
                }
                x = x + 32768;
            }
        }
    )";

    // Initialize CUDA
    cudaSetDevice(0);

    
    // Fill hostInput with data or load it from a file

    // Allocate memory on the device
    char* deviceInput;
    // char* deviceOutput;
    char* devicekey;
    cudaMalloc((void**)&deviceInput, BUF_SIZE);
    // cudaMalloc((void**)&deviceOutput, BUF_SIZE);
    cudaMalloc((void**)&devicekey, 129);

    // Copy data from host to device
    cudaMemcpy(deviceInput, hostInput, BUF_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(devicekey, key, 128, cudaMemcpyHostToDevice);

    // Create an NVRTC program and compile the CUDA source code
    nvrtcProgram program;
    nvrtcCreateProgram(&program, cudaSourceCode, "cuda.cu", 0, NULL, NULL);
    const char* options[] = { NULL };
    nvrtcCompileProgram(program,0, options);

    // Retrieve and print the compilation log
    size_t logSize;
    nvrtcGetProgramLogSize(program, &logSize);
    char* log = (char*)malloc(logSize);
    nvrtcGetProgramLog(program, log);
    printf("Compilation log:\n%s\n", log);
    free(log);

    // Retrieve the PTX code
    size_t ptxSize;
    nvrtcGetPTXSize(program, &ptxSize);
    char* ptx = (char*)malloc(ptxSize);
    nvrtcGetPTX(program, ptx);

    // Load the PTX code into a CUDA module
    CUmodule cuModule;
    cuModuleLoadDataEx(&cuModule, ptx, 0, 0, 0);

    // Get a function from the module
    CUfunction cuFunction;
    cuModuleGetFunction(&cuFunction, cuModule, "supCUDA");

    // Launch the kernel
    dim3 blockDim(32, 1);
    dim3 gridDim(8, 1);
    void* kernelParams[] = { &devicekey, &deviceInput };
    cuLaunchKernel(cuFunction, gridDim.x, gridDim.y, gridDim.z, blockDim.x, blockDim.y, blockDim.z, 0, 0, kernelParams, 0);
    cuCtxSynchronize();

    // Copy the results from the device to the host
    cudaMemcpy(hostInput, deviceInput, BUF_SIZE, cudaMemcpyDeviceToHost);

    // Perform any necessary post-processing with hostOutput data
    fwrite(hostInput,BUF_SIZE,1,writer);

    fclose(reader);
    fclose(writer);


    // Clean up resources
    nvrtcDestroyProgram(&program);
    free(ptx);
    free(hostInput);
    // free(hostOutput);
    cudaFree(deviceInput);
    // cudaFree(deviceOutput);
    cudaFree(devicekey);
    cuModuleUnload(cuModule);

    end = clock();
    time_spent = (double)(end - begin) / CLOCKS_PER_SEC;    
    printf("\n\nExecution time: %f seconds ",time_spent);

    cudaGetDeviceProperties(&deviceProp,0);
    // printf("\n%s",deviceProp.name);
    printf("\nProcessors: %d",deviceProp.multiProcessorCount);
    printf("\nCompute strength: %d",deviceProp.multiProcessorCount*deviceProp.warpSize);
    printf("\nFree memory: %llu\nTotal memory: %llu\n",freemem,totalmem);

    char file1[20]= "1.singlelock";
    char file2[20]="1.CUDAlock";
    // printf("Enter first file's name/path to file:\n");
    // scanf("%s",file1);
    // printf("Enter Second file's name/path to file:\n");
    // scanf("%s",file2);

    FILE* reader1 = fopen(file1,"rb");
    FILE* reader2 = fopen(file2,"rb");
    if(reader==NULL)
    {
        printf("\nError in opening/finding the file %s",file1);
        return 0;
    }
    if(reader2==NULL)
    {
        printf("\nError in opening/finding the file %s",file2);
        return 0;
    }
    unsigned long long int check=0,in[1],out[1];
    unsigned long long int count=0,size;

    fseek(reader,0,SEEK_END);
    size= ftell(reader);
    fseek(reader,0,SEEK_SET);

    printf("Checking files...\n");

    while (count<size)
    {
        fread(in,8,1,reader);
        fread(out,8,1,reader2);
        check = in[0]^out[0];
        if(check)
        {
            printf("\nERROR \n\nFound at byte %llu",count);
            goto jump;
        }
        count = count+8;
    }
    printf("\nNO ERROR\n\n%llu bytes verified",count);
    jump:
    fclose(reader);
    fclose(reader2);
    remove("1");
    remove("1.singlelock");
    remove("1.CUDAlock");
    
    return 0;
}
