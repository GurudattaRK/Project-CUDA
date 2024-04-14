#include<time.h>
#include<stdio.h>
#include<stdlib.h>

#define BUF_SIZE 1073741824

void supCUDA(void* keys,void* inputs, void* outputs)
{
    char* key= (char* ) keys;
    char* input= (char* ) inputs;
    char* output= (char* ) outputs;
    int x=0;
    for(int j=0;j<8388608;j++)
    {
      for(int i=0;i<128;i++)
      {
        output[x+i]= input[x+i] ^ key[i];
      }
      x=x+128;
    }
  return;
}
int main()
{
    
    void* buffer = calloc(BUF_SIZE,1);
    void* outbuffer = calloc(BUF_SIZE,1);
    char key[130] = "qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,qwertyuiopasdfghjklzxcvbnm,ouoq,re,xqe0,wuriov\0\0";

    clock_t begin,end;
    begin = clock();
    double time_spent;

    FILE* reader = fopen("1","rb");
    FILE* writer = fopen("1.singlelock","wb");

    fread(buffer,BUF_SIZE,1,reader);

    supCUDA(key,buffer,outbuffer);
    
    fwrite(outbuffer,BUF_SIZE,1,writer);

    free(buffer);
    free(outbuffer);

    fclose(reader);
    fclose(writer);

    end = clock();
    time_spent = (double)(end - begin) / CLOCKS_PER_SEC;    
    printf("\n\nExecution time: %f seconds ",time_spent);

    return 0;
}
