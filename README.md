## Script for mass conversion from simfs to ploop


Script for conversion to ploop OpenVZ disk layout from simfs.

Usage:
```bash
perl fast_convert_to_ploop.pl
```

If script found any overflowed by disk VE it add 1Gb of space to it.

Algorithm:
- Iterate over all runned and suspended CT
- Stop CT if it was active
- Convert to ploop
- Run VE again, if it was active 
