#include "svdpi.h"

void compute_out_buffer(svOpenArrayHandle data, svOpenArrayHandle out_buffer)
{
  int arr[];
  int size = svSize(data,1);
  for(int i=0;i<size;i++)
    arr[i] = data[i];

  
  
}
