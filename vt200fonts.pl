#!/usr/bin/perl

# convert a BDF font file to a DEC VT200 series terminal
#     downloadable soft font
# Leif.Harcke@stanford.edu
# 2002 November 1

while(<>) {
    if (/^STARTFONT/) {
	($kw,$vers) = split;
	print STDERR "Bitmap Distribution Format version: $vers\n";
    }
    if (/^FONTBOUNDINGBOX/) {
	($kw,$fbbx,$fbby,$xoff,$yoff) = split;
	print STDERR "Font size: ${fbbx}x${fbby}\n";
	$hexperrow = 2*&bytesperbit($fbbx,8);
	print STDERR "Hex digits per row: $hexperrow\n";
	$sxlpercol = &bytesperbit($fbby,6);
	print STDERR "Sixels per column: $sxlpercol\n";
    }
    if (/^CHARS /) {
	($kw, $nglyphs) = split;
	print STDERR "Total number of glyphs: $nglyphs\n";
    }
    if (/^ENCODING/) {
	($kw,$encoding) = split;
#	printf(STDERR "Starting glyph encoding $encoding (0x%02x)\n",$encoding);
    }
    if (/^BITMAP/) {
	@bitmap = ();
	while (<>) {
	    last if (/^ENDCHAR/);
	    chop;
	    push @bitmap, $_;
	}
 $glyphs[$encoding] = join("",&bmp2sxl(@bitmap));
    }
}

#write the output file

print "\x1bP0;1;0;3;0;0{ @";
for $i (161..254) {
#for $i (33..127) {
    $g = $glyphs[$i];
    if ($g eq "") {
	print "??????/??????;";
    } else {
 print $g, ";";
    }
}
print "\x1b\\";
print "\x1b* @";

# here we convert the bitmap to sixels
sub bmp2sxl {
    @bmp = ();
    foreach $row (@_) {
	push @bmp, [split("",unpack("B${fbbx}",pack("H${hexperrow}",$row)))];
    }
#    for $i (0..($fbby-1)) {
#	for $j (0..($fbbx-1)) {
#	    print $bmp[$i][$j];
#	}
#	print "\n";
#    }
    @out = ();
    for $ii (0..($sxlpercol-1)) {
	for $j (0..($fbbx-1)) {
	    @sixel = (0,0,0,0,0,0,0,0);
	    for $i (0..5) {
		if ($bmp[6*$ii+$i][$j]) {
		    $sixel[7-$i] = 1;
		}
	    }
	    $sixel = chr(ord(pack("B8",join("",@sixel))) + 63);
	    push @out, $sixel;
	}
	push @out, ("?","?");
	if ($ii < ($sxlpercol-1)) {
	    push @out, "/";
	}
    }
 return @out;
}

# determine the number of bytes we need to represent a number of bits
sub bytesperbit {
    my($nbits,$bpb) = @_;
    my($nbytes) = int($nbits/$bpb);
    if ($nbits%$bpb) {$nbytes++};
    return $nbytes;
}
