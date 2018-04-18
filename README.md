Written by Blacky, other than bTimes-extras. Charles (AKA Hypnos) has a destroyed-history [fork](https://github.com/CharlesBarone/bTimes) of this about half way through this repo's commit history. I am not maintaining this because I believe if I'm going to work on bhop I should put the effort towards Momentum.

The timer now uses SM 1.8+

If your server is experiencing heap overflows from the timer, try reducing the size of MAXNAME_LENGTH in `include/scp.inc`, although this bug may have been from the 1.6 compiler. The cause was never fully tracked down.
