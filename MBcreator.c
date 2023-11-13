#include<stdio.h>
int main()
{
    unsigned char buffer3[32768];
    char file[100]="1";
    int k;
    FILE *reader3 = fopen("MBcreator.exe","rb");
    fread(buffer3,32768,1,reader3); 

    // printf("Enter the name u want to give to the file:\n");
    // scanf("%s",file);
    // printf("Enter the size of the file u want to create(in MB):\n");
    // scanf("%d",&k);
    k=1024;
    FILE *writer3 = fopen(file,"wb");
    unsigned long long int t=0,g=32UL;
    g=g*k;
    while(t<g)
    {
        fwrite(buffer3,32768,1,writer3);
        t++;
        
    }
    fclose(reader3);
    fclose(writer3);
    printf("A 1 GB file named %s is created.",file);

}