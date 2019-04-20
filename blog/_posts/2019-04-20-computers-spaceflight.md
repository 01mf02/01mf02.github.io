---
title: '"Computers in Spaceflight" - remaking of a 1988 NASA book'
---


# Introduction

The movie [Apollo 13] stirred up my interest in the [Apollo program].
In particular, I was amazed by the computers shown therein.
Looking for information about this technology,
I discovered a [NASA website] that hosts historical information
not only about the computers of the Apollo,
but also about those of several other missions.
Absorbed in the content, I quickly wanted to read it in paper form.
However, the website was structured such that every section had an own page,
so printing the whole website content would certainly have not looked nice.
Fortunately, I found out that the website took its content directly from
a book called "Computers in Spaceflight: The NASA Experience".
Written by James E. Tomayko and published in 1988,
it is freely distributed by NASA as a [PDF][Original PDF].
However, the PDF version was nearly 500MB large,
thus making it unsuitable for printing as well.

That moment, I had an idea to challenge myself:
Could I in a single afternoon
extract from the NASA website all the content from the book and
make it into a nice-looking PDF?
This post describes the resulting process and explains why in the end,
it took me from end of July to beginning of November 2018
to finish this project.


# Automated Processing

In the beginning, I downloaded all files from the NASA website via `wget` and
converted the HTML files to PDF via [Pandoc]:

    pandoc *.html -o test.pdf

The result was encouraging:
Even though the order of the chapters was wrong,
the resulting PDF was roughly the same size as the original book
(463 pages vs. 406) and even contained images.
At a closer inspection, though, it became clear that editing was required:
For example, all the HTML files contained some site navigation elements
that showed up also in the PDF.
Furthermore, headlines were just boldfaced text, which led to some
very ugly page breaks between headlines and the following text.
It quickly became clear that I had to
process the original HTML files before passing them to Pandoc,
such that Pandoc could correctly recognise e.g. headlines.
My plan was to create readable Markdown files from the HTML files,
which in turn Pandoc could convert to PDF and several other formats.
Given the sheer size of the book, I wanted this to automate this processing.
I will now give an overview of this automated processing.

When looking at the HTML files for the first time,
I could hardly read anything, as they were encoded in DOS format,
so line breaks were only displayed as ugly `^M` in my file editor.
Thus my first step was to convert these files to Unix format with

    tr "\r" "\n" < in.html > out.html

Next, I found that the HTML files were full of useless tags.
In particular, lines like

~~~ html
<DD><FONT FACE="Geneva">&nbsp;</FONT>
~~~

were literally sprinkled everywhere!
So I found the `tidy` tool whose purpose is to clean up HTML files.
Trying it on the HTML files, it gave me errors, in particular because
the HTML files contained tags that `tidy` did not recognise.
Fortunately, after several rounds of `sed` and `perl` to remove
the worst HTML abominations (unrecognised tags, unclosed tags etc.)
I was able to run `tidy`.
This yielded some HTML that was easier to process automatically.
Step by step, I created `sed` and `perl` one-liners, of which
each massaged the HTML a bit further to remove superfluous information.
One command would remove the navigation bars from every HTML page,
another would remove `br` tags, another would remove block quotes ...
In between all this, I ran `tidy` a total of four times to ensure that
tags which were made empty by my processing scripts would be removed,
thus not obstructing future processing steps.
In short, it was a mess.
But a lot of fun and perfect to hone my regular expression skills. :)

Sometimes, I figured out that an earlier processing step had
removed information that was required at a later step,
for example removing some tags that were necessary later to recognise headlines.
This made it necessary from time to time to
move processing steps to later or earlier points and rerun the processing.
I kept the intermediate results of every processing step,
to be able to see which processing step had caused a certain problem.
While I started with a large Bash script, it turned out to be
very error-prone to keep track of the dependencies between the processing steps.
Therefore, I converted the Bash script to a `Makefile`,
which tremendously helped to keep the whole process manageable.
For example, I expressed the conversion to Unix format
followed by the removal of `FONT` tags as follows:

~~~ make
i/unix/%.html: i/filenames/%.html
	@mkdir -p `dirname $@`
	tr "\r" "\n" < $< > $@

i/nofont/%.html: i/unix/%.html
	@mkdir -p `dirname $@`
	perl -0777p -e 's|<.?FONT.*?>||gs' $< > $@
~~~

The final result consisted of 34 (!) automatic HTML processing steps
(similar to the ones shown above)
before the conversion to Markdown could take place.
Except for the conversion from DOS to Unix format via `tr`,
all processing steps used either `sed`, `perl`, or `tidy`
(in that order of frequency).
In particular, `perl` turned out to be useful because of
its non-greedy patterns and its pattern matching across several lines.


# Manual Processing

At this point, I was able to create a printable PDF via Pandoc
from the automatically generated Markdown files,
but my lust for perfection only awakened then.
In particular, the online version of the book contained information about
where page breaks took place in the original book.
For example, a marker like **[42]** in the HTML page signified that
at the marker's place, page 42 began in the original book.
Given the availability of this information,
I was now tempted to recreate the page numbers of the original book,
i.e. in my generated PDF,
page 42 should contain the same content as page 42 of the original book.
For this, I converted the page break markers to LaTeX commands `\pagebreak`.
However, to avoid LaTeX breaking a page before the actual `\pagebreak`,
it was necessary to reproduce the font and page layout of the original book.
To find the right font, I created a high-resolution screenshot of the original PDF
and uploaded it to an online font recognition service.
This yielded that the original book used a Times-like font.
To recreate the page layout faithfully, including headers and footers, I used
the [KOMA-Script] book class which served me well for this purpose.

After seemingly endless tweaking, I printed a PDF version and proofread it.
This yielded a large number of mistakes that
were already present in the HTML version of the book,
and which I subsequently corrected in my version.
For example, some parts were completely missing, such as the
"Interviews Conducted by Other Persons",
but there were also many typos.
Many of these indicated that an OCR software was used in the making of the HTML:
For example, in Box 2-1 of chapter 2-5, there were
four occurrences of the word "he" where "be" would have been correct.
Furthermore, in the same chapter, "16-bit" was four times written as "1 6-bit".
Probably, the person that looked over the output of the OCR
was just tired the day he or she worked on that chapter. :)

Furthermore, I also found some errors in the original.
In particular, the bibliography contained quite a few, and
the error rate in code listings such as Figure II-1 skyrocketed:
Keywords like `DECLARE` were misspelled as `DELCARE`, and
in the comments, there were several typos such as
"procure" instead of "procedure", and
"incontrolled manner" instead of "in controlled manner".
After finding these errors in the code listings,
I converted the code listings (which were given as images on the NASA website)
to text so I could correct the errors.
I proceeded as follows:

To crop away the figure caption:

    convert p396.jpg -chop 0x180 p396s.jpg

To perform OCR via [Tesseract], using settings for a typewriter font:

    tesseract p396s.jpg p396.txt --oem 3 --psm 6 -c preserve_interword_spaces=1

Finally, to remove unneeded blank lines introduced by the OCR:

    sed -i '/^$/d' p396.txt.txt

The result of Tesseract was not great, so I still had to correct a lot manually.
As a nice side effect of this image conversion,
the code listings are now actually well-readable and searchable.
A quick search on the internet yielded that before this project,
these source codes seem not to have been available in text form anywhere.


# Conclusion

After about three months of work, I had finally achieved
what I originally set out to do in a single afternoon. :)
The end result is a clean, printable, and searchable PDF which
reproduces the page numbers and the general look of the original.
Furthermore, it is also possible to create HTML or e-book versions,
but I have not ventured too much into this direction.

I hope that this re-editing of this book will allow interested readers
to have easier access to this source of fascinating information about
computers in spaceflight.

The source code, including the `Makefile` for automatic processing and PDF generation,
can be found on [GitHub].
There, you can also read the individual chapters in Markdown format,
including pictures.[^markdown]
The (for now) final PDF can be obtained [here][Final PDF].

[^markdown]: Unfortunately, some features of Pandoc Markdown are not supported by GitHub, so some things, such as references, are not correctly displayed. Still, to get a first impression or to just read the text, it should be sufficient.

[Apollo program]: https://en.wikipedia.org/wiki/Apollo_program
[Apollo 13]: https://en.wikipedia.org/wiki/Apollo_13_(film)
[NASA website]: https://history.nasa.gov/computers/contents.html
[Original PDF]: https://www.ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19880069935.pdf
[Initial commit]: https://github.com/01mf02/computers-spaceflight/commit/ba968f13888557de9df189d487f2c8b7c006c735
[Pandoc]: http://pandoc.org/
[KOMA-Script]: https://komascript.de/
[Tesseract]: https://github.com/tesseract-ocr/tesseract
[GitHub]: https://github.com/01mf02/computers-spaceflight
[Final PDF]: https://github.com/01mf02/computers-spaceflight/releases/download/v1.0/cisf-20181105.pdf
