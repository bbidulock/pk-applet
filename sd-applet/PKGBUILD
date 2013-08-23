pkgname=sd-applet
pkgver=0.01
pkgrel=1
pkgdesc="Systemd applet (tray icon)"
arch=('any')
url="http://www.unexicon.com/"
license=('Perl')
depends=('perl' 'systemd')
options=('!emptydirs')
source=(${pkgname}-${pkgver}.tar.gz)
md5sums=('fe45a479d8ee1a5f055345c3a93d38ee')

build() {
  cd $srcdir/$pkgname-$pkgver
  PERL_MM_USE_DEFAULT=1 perl Makefile.PL INSTALLSITESCRIPT=/usr/bin
  make
}
package() {
  cd $srcdir/$pkgname-$pkgver
  make install DESTDIR=$pkgdir
  find $pkgdir -name '.packlist' -delete
  find $pkgdir -name '*.pod' -delete
}
md5sums=('6645f06590c48721b0a6e5c602575b5c')
