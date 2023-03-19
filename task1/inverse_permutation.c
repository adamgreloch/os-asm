#include <stddef.h>
#include <stdbool.h>

bool inverse_permutation(size_t n, int *p) {
  // Check whether p is a proper n-permutation
  int zero = 0;
  bool good = true;

  for (int i = 0; i < n; i++) {
    if (p[i] == 0) zero++;
    if (p[i] < 0 || p[i] > n-1 || zero > 1) good = false;
    p[i] = -p[i];
  }

  for (int i = 0; i < n; i++) {
    if (p[i] <= 0) p[i] = -p[i];
    else good = false;
  }

  if (!good) return false;

  // Huang, 1981
  int m = n;
  int j = -1;
  int i;
  while (m > 0) {
    i = p[m];
    while (i > 0) {
      p[m] = j;
      j = -m;
      m = i;
      i = p[m];
    }
    i = j;
    p[m] = -i;
    m--;
  }
  return true;
}
