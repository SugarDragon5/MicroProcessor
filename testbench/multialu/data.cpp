#include<bits/stdc++.h>
using namespace std;

int main(){
    int32_t a, b;
    cin >> a >> b;
    int64_t c = (int64_t)a*b;
    printf("a: %lld, b: %lld\n", a, b);
    printf("dec: %lld\n", c);
    printf("hex: 0x%016llx\n", c);
    printf("bin: %s\n", bitset<64>(c).to_string().c_str());
    return 0;
}