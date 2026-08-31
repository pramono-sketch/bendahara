#include <iostream> 
#include <vector> 
using namespace std; 
int main() { 
int N = 4; 
int totalPanjang = 0; 
// Chiko ingin menghitung total panjang lahan dari 1 sampai N 
for (int i = 0; i <= N; i++) { // <-- BUG 1? 
if (i % 2 == 1) { 
// Rumus lahan ganjil: (i+1)/2 
totalPanjang = totalPanjang + (i + 1) / 2; 
} else { 
// Rumus lahan genap: N + 1 - (i/2) 
totalPanjang = (N + 1) - i / 2; // <-- BUG 2? 
} 
} 
cout << "Total panjang lahan Chiko: " << totalPanjang << endl; // <-- BUG 3? 
return 0; 
}