#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Tom Krauss
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
#
# This module implements discrete Fourier transforms.
#
# Computes the FFT and inverse FFT of a length N complex sequence.
# This is a rather simplistic, bare-bones implementation that uses
# recursion rather than looping.  It runs in O(N log N) time but is
# _not_ the fastest of algorithms.  Some simple optimizations have
# been made, but speed is not the main goal.
#
# Limitations
# -----------
#   -  requires that N is a power of 2
#
#   -  not the most memory efficient algorithm (returns a new
#      vector rather than performing it in place)
#
#


# Probably don't want to trace into these library routines
###{.push checks:off, line_dir:off, stack_trace:off, debugger:off.}

import math, complex

# We'll use these internally for the fftshift.  They should
# probably be in the math module.
proc ceil*(x: float): int {.importc: "ceil", header: "<math.h>".}
proc floor*(x: float): int {.importc: "floor", header: "<math.h>".}
proc isEven*(x: int): bool =
  result = (x%%2)==0

proc FFT*(x: seq[Complex64]): seq[Complex64] {.inline.}
  ## Compute the forward FFT of sequence x[]. Requires the length of x
  ## to be a power of 2.  The return is _not_ scaled by 1/N.
  
proc IFFT*(x: seq[Complex64]): seq[Complex64] {.inline.}
  ## Compute the inverse FFT of sequence x[], requires the length of x
  ## to be a power of 2.  The return is scaled by 1/N.


type
  TDirection* = enum
    forward, inverse
  ## Internal enumeration to specified FFT direction.  We don't
  ## (can't) use this outside of this module.



proc FFT*(x: seq[Complex64], dir: TDirection): seq[Complex64] =
  ## The main FFT routine.  This performs either a forward or inverse
  ## FFT based on the `dir` parameter.  The length of x must be a power
  ## of 2 (it is not checked in this routine).
  var N: int = len(x)
  var i: Complex64 = complex64(0.0,1.0)
  
  # The sign of the kernel.  This is the only difference between forward
  # and inverse in this routine.  Scaling is done outside of here.
  var s = 1.0
  case dir
  of forward: s = -1.0
  of inverse: s = 1.0

  # The Fourier kernel.  Note that arccos(-1)=PI.  We could/should
  # just use PI here but until the immediate float write bug is 
  # fixed the value of PI is hosed.  We'll jsut compute it
  # instead.  
  var g: Complex64 = exp(s*2.0*arccos(-1.0)*i/float(N))
    
  if N==1:
    # Length 1 FFT - simple.  This is the "end case" of the recursion
    # (usually anyway).
    result = x
  elif N==4:
    # We can compute a length 4 FFT directly.  We'll do that here
    # to reduce the number of recursive calls (save ~10% or so).
    # This case isn't strictly necessary, but it helps speed things
    # up a bit.
    newSeq(result,4)
    result[0] = x[0] +     x[1] + x[2] +     x[3]
    result[1] = x[0] + i*s*x[1] - x[2] - i*s*x[3]
    result[2] = x[0] -     x[1] + x[2] -     x[3]
    result[3] = x[0] - i*s*x[1] - x[2] + i*s*x[3]
  else:
    # The general case.  Here we'll compute the FFT recursively.  First
    # get the FFT of the even samples and the odd samples, then combine
    # the results.
    
    # The even and odd sequences (of length N/2)...
    var m = int(N/2)
    var even: seq[Complex64]
    var odd: seq[Complex64]
    newSeq(even,m)
    newSeq(odd,m)
    for k in countup(0,m-1):
      even[k] = x[2*k] 
      odd[k]  = x[2*k+1]
    
    # ...and their FFTs
    even = FFT(even, dir)
    odd  = FFT(odd, dir)


    # Now combine the even and odd sequences.  Here `d` is
    # the Fourier kernel exp(+-2 PI i k/N)   
    var d: seq[Complex64]
    newSeq(d,m)
    for k in countup(0,m-1):
      d[k] = pow( g, complex64(float(k),0.0) )
    
    newSeq(result,N)
    for k in countup(0,m-1):
      result[k]   = even[k] + d[k]*odd[k]
      result[m+k] = even[k] - d[k]*odd[k]
      


proc FFT*(x: seq[Complex64]): seq[Complex64] =
  ## Compute the forward FFT of sequence x[]. Requires the length of x
  ## to be a power of 2.  The return is _not_ scaled by 1/N.
  assert( isPowerOfTwo(len(x)) )
  result = FFT(x,forward)
  
  
proc IFFT*(x: seq[Complex64]): seq[Complex64] =
  ## Compute the inverse FFT of sequence x[], requires the length of x
  ## to be a power of 2.  The return is scaled by 1/N.
  assert( isPowerOfTwo(len(x)) )
  result = FFT(x,inverse)
  for k in countup(0,len(result)-1):
    result[k] = result[k] / float(len(x))




proc fftshift*[T](x: seq[T]): seq[T] =
  ## Rearranges the outputs of fft and ifft so the zero-frequency component
  ## is at the center of the array. It is useful for visualizing a Fourier
  ## transform to have the zero-frequency component in the middle of the 
  ## spectrum.
  var N:  int = len(x)
  var N2: int = ceil(N/2)
  result = @[]
  setlen(result,N)

  if isEven(N):
    for i in countup(0,N2-1):
       result[i+N2] = x[i]
    for i in countup(N2,N-1):
       result[i-N2] = x[i]
  else:
    for i in countup(0,N2-1):
       result[i+N2-1] = x[i]
    for i in countup(N2,N-1):
       result[i-N2] = x[i]




  

# when isMainModule:
#   var data = @[ (-1.0,0.0), (1.0,0.0), (-1.0,0.0), (1.0,0.0), (-1.0,0.0), (1.0,0.0), (-1.0,0.0), (1.0,0.0) ]
#   var ans  = @[ (0.0,0.0), (0.0,0.0), (0.0,0.0), (0.0,0.0), (-8.0,0.0), (0.0,0.0), (0.0,0.0), (0.0,0.0) ]
#   assert( fft(data) == ans )

#   # Even and odd length arrays for fftshift
#   assert( fftshift( @[1,2,3,4,5] ) == @[4,5,1,2,3] )
#   assert( fftshift( @[1,2,3,4,5,6] ) == @[4,5,6,1,2,3] )