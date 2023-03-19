#include <limits.h>
#include <stdbool.h>
#include <stddef.h>

bool inverse_permutation(size_t n, int *p) {
    if (n == 0 || n > (size_t) INT_MAX + 1) return false;

    bool good = true;

    for (int i = 0; i < n; i++)
        if (p[i] >= 0 && p[i] < n)
            p[i]++;
        else {
            for (int k = i - 1; k >= 0; k--)
                p[k]--;
            return false;
        }

    int idx;

    for (int k = 1; k >= 0; k--)
        for (int i = 0; i < n; i++) {
            idx = p[i];
            if (idx < 0) idx = -idx;
            if ((k-1) * p[idx-1] >= 0) p[idx-1] = -p[idx-1];
            else good = false;
        }

    if (!good) {
        for (int i = 0; i < n; i++)
            p[i]--;
        return false;
    }

    int m = n;
    int j = -1;
    int i;
    while (m > 0) {
        i = p[m-1];
        while (i > 0) {
            p[m-1] = j;
            j = -m;
            m = i;
            i = p[m-1];
            if (i < 0) i = j;
        }
        p[m-1] = -i;
        m--;
    }

    for (int i = 0; i < n; i++) p[i]--;
    return true;
}
