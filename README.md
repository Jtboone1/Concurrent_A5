# Implementation
We used CUDA to create an image filter that divides the number of pixels
needing to be filtered with the number of total threads the user specifies.

### Requirements
We used the NVIDIA CUDA Toolkit

### How to compile
` nvcc main -o main.exe `

### How to run
```
./main.exe <#Blocks> <#Threads>

Required: 65536 % (#Blocks * #Threads) == 0
```
<br/>
To profile, we can use ` nvprof ` from the NVIDIA CUDA Toolkit:

` nvprof ./main.exe <#Blocks> <#Threads> `

<br/>
Some useful commands to disable some of the API reporting:
<br/>

` --profile-api-trace none `
` --unified-memory-profiling off `

### Performance Comparisons
TODO