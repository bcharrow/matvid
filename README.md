# Installation

Just put the files somewhere on your Matlab path.  There are also some required system commands:

    epstopdf librsvg convert ffmpeg

We use ffmpeg and not avconv because that's what [homebrew decided](http://librelist.com/browser//homebrew/2011/10/24/libav-conflicts-with-ffmpeg-thoughts/).  

To grab plots with transparencies, we use ```plot2svg``` which you can get from the [file exchange](http://www.mathworks.com/matlabcentral/fileexchange/7401)


## Ubuntu

     apt-get install librsvg2-bin imagemagick

Depending on your distro, the ffmpeg verison in the repos may be out of date. Newer versions of ffmpeg are substantially better at compressing things with reasonable qualities so it's probably worth it to get a more recent version.

* [Recent static build](http://dl.dropbox.com/u/24633983/ffmpeg/index.html) (Recommended)

* [Slightly out of date packages](https://launchpad.net/~jon-severinsson/+archive/ffmpeg)

* [ffmpeg download site](http://ffmpeg.org/download.html)


## OS X (Homebrew)

    brew install ffmpeg librsvg imagemagick

On 10.6 we've had issues with librsvg and libpng versions.  Installing the latest version of [xquartz](http://xquartz.macosforge.org) fixes them.

To ensure Matlab can find all of the needed system calls, make sure PATH is set properly.  If you launch matlab via the terminal, this shouldn't be a problem.  However, if you launch via the dock or spotlight, you probably want to edit ```/etc/launchd.conf```  (see this [thread](http://stackoverflow.com/questions/135688/setting-environment-variables-in-os-x)) Here's example file contents

    setenv PATH /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/X11/bin

After you edit the file, you'll need to reboot for changes to take effect.  Note that this will set your path for *all* applications.  