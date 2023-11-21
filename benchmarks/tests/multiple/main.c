int f1(){
  int x=0;
  for(int i=0;i<100;i++){
    x+=i*i;
  }
  return x;
}

int f2(){
  long x=0;
  for(int i=100000;i<1000000;i+=100000){
    x+=i*i;
  }
  return x;
}

int main(){
  return f1()+f2();
}
