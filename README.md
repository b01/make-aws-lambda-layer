# Make AWS Lambda Layer

A shell script (POSIX compliant) to locally build a zip and upload to AWS Lambda
as a layer.

## Guidelines

When contributing, please try to:

1. Follow POSIX standards - keep this script POSIX compliant. So please no
   non-POSIX shell foo, like things that only work in bash or other flavors of
   shell should be avoided.
2. Test - This should be safe to test locally with no cost in AWS as long as
   you delete the layers and don't go pass free-tier.

---

[sh Linux manual (man7)]: https://man7.org/linux/man-pages/man1/sh.1p.html
