---
layout: post
title: "Simple, accurate eye center tracking in OpenCV"
description: ""
category: projects
tags:
- compsci
- eyeLike
- eye tracking
---
{% include JB/setup %}

I am currently working on writing [an open source gaze tracker](http://github.com/trishume/eyeLike) in OpenCV that requires only a webcam.
One of the things necessary for any gaze tracker[^1] is accurate tracking of the eye center.

For my gaze tracker I had the following constraints:
- Must work on low resolution images.
- Must be able to run in real time.
- I must be able to implement it with only high school level math knowledge.
- Must be accurate enough to be used for gaze tracking.

I came across a paper[^2] by Fabian Timm that details an algorithm that fit all of my criteria.
It uses image gradients and dot products to create a function that theoretically is at a maximum at the center of the image's most prominent circle.

Here is a video he made of his algorithm in action:

<iframe width="560" height="315" src="http://www.youtube.com/embed/aGmGyFLQAFM" frameborder="0" allowfullscreen="">
</iframe>

**Before continuing I recommend that you read [his paper](https://www.inb.uni-luebeck.de/fileadmin/files/PUBPDFS/TiBa11b.pdf).**

# Implementing the algorithm

After implementing the algorithm detailed in the paper using OpenCV functions my implementation had horrendous accuracy and many problems. These were partially caused by the paper not specifying some important numbers.

These numbers include:
- The eye region fractions.
- The gradient magnitude threshold.
- The size of the eye regions used.

I contacted Dr. Timm and he helped me with some of my problems.
Below are some problems that I resolved with Dr. Timm's help.

## Things That Are Not in the Paper

The first thing I fixed was the eye region fractions as portions of the face. From Dr. Timm:

> Let (x, y) be the upper left corner and W, H the width and height of the detected face.
> Then, the mean of the right eye centre is located at (x + 0.3, y + 0) and the mean of the left centre is at position (x + 0.7, y + 0.4).

On his recommendation I also applied a gaussian blur to the face before processing it to smooth noise. I use the sigma of `0.005 * sideLengthOfFace`.

### The Gradient Algorithm

One important thing that is not explained very clearly in the paper is the gradient algorithm. In his implementation he uses the MatLab `gradient` function. In my original implementation I used a Sobel operator but by imitating MatLab's gradient function I achieved much better results.

The way MatLab's gradient algorithm works (in Matlab code) is `[x(2)-x(1) (x(3:end)-x(1:end-2))/2 x(end)-x(end-1)]` with x being the input. Translated into C++ and OpenCV this comes out as:

{% highlight c++ %}
cv::Mat computeMatXGradient(const cv::Mat &mat) {
  cv::Mat out(mat.rows,mat.cols,CV_64F);

  for (int y = 0; y < mat.rows; ++y) {
    const uchar *Mr = mat.ptr<uchar>(y);
    double *Or = out.ptr<double>(y);

    Or[0] = Mr[1] - Mr[0];
    for (int x = 1; x < mat.cols - 1; ++x) {
      Or[x] = (Mr[x+1] - Mr[x-1])/2.0;
    }
    Or[mat.cols-1] = Mr[mat.cols-1] - Mr[mat.cols-2];
  }

  return out;
}
{% endhighlight %}

to get the Y gradient I simply take the X gradient of the transpose matrix and transpose it again(`computeMatXGradient(eyeROI.t()).t()`)

By replicating his gradient algorithm I was also able to use the same gradient threshold as him. From Dr. Timm:

> I remove all gradients that are below this threshold:
>
> `0.3 * stdMagnGrad + meanMagnGrad`
>
> where "stdMagnGrad" and "meanMagnGrad" are the standard deviation and the mean of all gradient magnitudes, i.e. the length of the gradients.;

### The "Little Thing" that he didn't mention

Because his algorithm in the form he gives in the paper is generalized to all circles he left out one tiny important thing. For me this one line of code made the difference between it working and being terribly innacurate.

In the equation he gives the dot product of the `d` vector and the gradient is taken and then squared. The thing is this makes negative dot products positive.

Dot products are negative if the vectors are pointing in opposite directions. The gradient function used creates vectors that always point towards the lighter region. Since the iris is darker than the sclera (white part) the vectors of the iris edge always point out. This means that at the center they will be facing in the same direction as the `d` vector. **Anything pointing in the opposite direction is irrelevant**

To fix this I added a line of code that turns negative values into zero so they have no effect on the result:
`dotProduct = std::max(0.0,dotProduct);`

After adding this line of code my implementation tracked my eyes excellently and worked exactly as it should.

#Conclusion

Dr. Timm's eye center location algorithm is an excellent simple way to track the pupil, but only if you add a few extra things that he does not talk about in his paper.

In terms of my eye tracker at the moment this is all I have implemented. I am
still looking into methods of tracking a reference point like eye corner to
accurately judge where the user is looking.

I am also looking into using deformation of the eye into an oval to
determine the orientation of the iris.

[^1]: An eye tracker gives the pixel position of the center of the pupil in an image whereas a gaze tracker determines where the person is looking on the screen.
[^2]: Timm and Barth. Accurate eye centre localisation by means of gradients. In Proceedings of the Int. Conference on Computer Theory and Applications (VISAPP), volume 1, pages 125-130, Algarve, Portugal, 2011. INSTICC.
