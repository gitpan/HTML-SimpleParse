package HTML::SimpleParse;

use strict;
use vars qw($VERSION);

$VERSION = '0.06';
my $debug = 0;

sub new {
	my $pack = shift;

	my $self = bless {
		'text' => shift(),
		'tree' => [],
	}, $pack;

	$self->parse if length $self->{'text'};
	return $self;
}

sub text {
	my $self = shift;
	$self->{'text'} = shift if @_;
	return $self->{'text'};
}

sub tree { @{$_[0]->{'tree'}} }

sub parse {
	# Much of this is a dumbed-down version of HTML::Parser::parse.
	
	my $self = shift;
	my $text = \ $self->{'text'};
	my $tree = $self->{'tree'};

	# Parse html text in $$text.  The strategy is to remove complete
	# tokens from the beginning of $$text until we can't decide whether
	# it is a token or not, or the $$text is empty.

	@$tree = ();
	while (1) {
		my ($content, $type);

		# First we try to pull off any plain text (anything before a "<" char)
		if ($$text =~ /\G([^<]+)/gcs) {
			$content = $1; $type = 'text';

		# Then, SSI, comments, and markup declarations (usually <!DOCTYPE...>)
		# ssi:     <!--#stuff-->
		# comment: <!--stuff-->
		# markup:  <!stuff>
		} elsif ($$text =~ /\G<(!--(\#?).*?--)>/gcs) {
			$type = ($2 ? 'ssi' : 'comment');
			$content = $1;

		} elsif ($$text =~ /\G<(!.*?)>/gcs) {
			$type = 'markup';
			$content = $1;

		# Then, look for an end tag
		} elsif ($$text =~ m|\G<(/[a-zA-Z][a-zA-Z0-9\.\-]*\s*)>|gcs) {
			$content = $1; $type = 'endtag';

		# Then, finally we look for a start tag
		# We know the first char is <, make sure there's a >
		} elsif ($$text =~ /\G<(.*?)>/gcs) {
			$content = $1; $type = 'starttag';

		} else {
			# the string is exhausted, or there's no > in it.
			push @$tree, {
				'content'	=> substr($$text, pos $$text),
				'type'		=> 'text',
			} unless pos($$text) eq length($$text);
			last;
		}
		
		push @$tree, {
			'content'	=> $content,
			'type'		=> $type,
		};
	}

	$self;
}

sub parse_args {
	my $self = shift;  # Not needed here
	my @returns;
	
	pos($_[0]) = 0;  # Make sure we start searching at the beginning of the string

	while (1) {
		next if $_[0] =~ m/\G\s+/gc;  # Get rid of leading whitespace

		if ( $_[0] =~ m/\G
			(\S+?)=                                  # the key
			(?:
			 "([^\"\\]*  (?: \\.[^\"\\]* )* )"\s*    # quoted string, with possible whitespace inside,
			  |                                      #  or
			 ([^\s>]*)\s*                            # anything else, without whitespace or >
		   )/gcx ) {

			my ($key, $val) = ($1, $+);
			$val =~ s/\\(.)/$1/gs;
			push @returns, $key, $val;

		} elsif ( $_[0] =~ m/\G(\S+)\s*/gc ) {
			push @returns, $1, undef;
		} else {
			last;
		}
	}

	return @returns;
}


sub execute {
	my $self = shift;
	my $ref = shift;
	my $method = "output_$ref->{type}";
	warn "calling $self->$method(...)" if $debug;
	return $self->$method($ref->{content});
}

sub get_output {
	my $self = shift;
	my ($method, $out) = ('', '');
	foreach ($self->tree) {
		$out .= $self->execute($_);
	}
	return $out;
}


sub output {
	my $self = shift;
	my $method;
	foreach ($self->tree) {
		print $self->execute($_);
	}
}

sub output_text      {   $_[1]; }
sub output_comment   { "<$_[1]>"; }
sub output_endtag    { "<$_[1]>"; }
sub output_starttag  { "<$_[1]>"; }
sub output_markup    { "<$_[1]>"; }
sub output_ssi       { "<$_[1]>"; }

1;
__END__

=head1 NAME

HTML::SimpleParse - a bare-bones HTML parser

=head1 SYNOPSIS

 use HTML::SimpleParse;

 # Parse the text into a simple tree
 my $p = new HTML::SimpleParse( $html_text );
 $p->output;                 # Output the HTML verbatim
 
 $p->text( $new_text );      # Give it some new HTML to chew on
 $p->parse                   # Parse the new HTML
 $p->output;

=head1 DESCRIPTION

This module is a simple HTML parser.  It is similar in concept to HTML::Parser,
but it differs in a couple of important ways.  

First, HTML::Parser knows which
tags can contain other tags, which start tags have corresponding end tags, which
tags can exist only in the <HEAD> portion of the document, and so forth.  
HTML::SimpleParse does not know any of these things.  It just finds tags and text
in the HTML you give it, it does not care about the specific content of these tags
(though it does distiguish between different _types_ of tags, such as comments,
starting tags like <b>, ending tags like </b>, and so on).

Second, HTML::SimpleParse does not create a hierarchical tree of HTML content,
but rather a simple linear list.  It does not pay any attention to balancing
start tags with corresponding end tags, or which pairs of tags are inside other
pairs of tags.

Because of these characteristics, you can make a very effective HTML
filter by sub-classing HTML::SimpleParse.  For example, to remove all comments 
from HTML:

 package NoComment;
 use HTML::SimpleParse;
 @ISA = qw(HTML::SimpleParse);
 sub output_comment {}
 
 package main;
 NoComment->new($some_html)->output;

=head2 Methods

=over 4

=item * new

 $p = new HTML::SimpleParse( $some_html );

Creates a new HTML::SimpleParse object.  Optionally takes one argument,
a string containing some HTML with which to initialize the object.  If
you give it a non-empty string, the HTML will be parsed into a tree and 
ready for outputting.

=item * text

 $text = $p->text;
 $p->text( $new_text );

Get or set the contents of the HTML to be parsed.

=item * tree

 foreach ($p->tree) { ... }

Returns a list of all the nodes in the tree, in case you want to step
through them manually or something.  Each node in the tree is an anonymous
hash with (at least) two data members, $node->{type} (is this a comment,
a start tag, an end tag, etc.) and $node->{content} (all the text between
the angle brackets, verbatim).

=item * parse

 $p->parse;

Once an object has been initialized with some text, call $p->parse and 
a tree will be created.  After the tree is created, you can call $p->output.
If you feed some text to the new() method, parse will be called automatically
during your object's construction.

=item * parse_args

 %hash = $p->parse_args( $arg_string );

This routine is handy for parsing the contents of an HTML tag into key=value
pairs.  For instance:

  $text = 'type=checkbox checked name=flavor value="chocolate or strawberry"';
  %hash = $p->parse_args( $text );
  # %hash is ( type=>'checkbox', checked=>undef, name=>'flavor',
  #            value=>'chocolate or strawberry' )

Note that the position of the last m//g search on the string (the value 
returned by Perl's pos() function) will be altered by the parse_args function,
so make sure you take that into account if (in the above example) you do
C<$text =~ m/something/g>.

If an attribute takes no value (like "checked" in the above example) then it
will still have an entry in the returned hash, but its value will be C<undef>.
For example:

  %hash = $p->parse_args('type=checkbox checked name=banana value=""');
  # $hash{checked} is undef, but $hash{value} is ""

This method actually returns a list (not a hash), so duplicate attributes and
order will be preserved if you want them to be:

 @hash = $p->parse_args("name=family value=gwen value=mom value=pop");
 # @hash is qw(name family value gwen value mom value pop)

=item * output

 $p->output;

This will output the contents of the HTML, passing the real work off to
the output_text, output_comment, etc. functions.  If you do not override any
of these methods, this module will output the exact text that it parsed into
a tree in the first place.

=item * get_output

 print $p->get_output

Similar to $p->output(), but returns its result instead of printing it.

=item * execute

 foreach ($p->tree) {
    print $p->execute($_);
 }

Executes a single node in the HTML parse tree.  Useful if you want to loop
through the nodes and output them individually.

=back

The following methods do the actual outputting of the various parts of
the HTML.  Override some of them if you want to change the way the HTML
is output.  For instance, to strip comments from the HTML, override the
output_comment method like so:

 # In subclass:
 sub output_comment { }  # Does nothing

=over 4

=item * output_text

=item * output_comment

=item * output_endtag

=item * output_starttag

=item * output_markup

=item * output_ssi


=back

=head1 CAVEATS

Please do not assume that the interface here is stable.  This is a first pass, 
and I'm still trying to incorporate suggestions from the community.  If you
employ this module somewhere, make doubly sure before upgrading that none of your
code breaks when you use the newer version.


=head1 BUGS

=over 4

=item * Embedded >s are broken

Won't handle tags with embedded >s in them, like
<input name=expr value="x > y">.  This will be fixed in a future
version, probably by using the parse_args method.  Suggestions are welcome.

=back

=head1 TO DO

=over 4

=item * extensibility

Based on a suggestion from Randy Harmon (thanks), I'd like to make it easier
for subclasses of SimpleParse to pick out other kinds of HTML blocks, i.e.
extend the set {text, comment, endtag, starttag, markup, ssi} to include more
members.  Currently the only easy way to do that is by overriding the 
C<parse> method:

 sub parse {  # In subclass
    my $self = $_[0];
    $self->SUPER::parse(@_);
    foreach ($self->tree) {
       if ($_->{content} =~ m#^a\s+#i) {
          $_->{type} = 'anchor_start';
       }
    }
 }

 sub output_anchor_start {
    # Whatever you want...
 }

Alternatively, this feature might be implemented by hanging attatchments 
onto the parsing loop, like this:

 my $parser = new SimpleParse( $html_text );
 $regex = '<(a\s+.*?)>';
 $parser->watch_for( 'anchor_start', $regex );
 
 sub SimpleParse::output_anchor_start {
    # Whatever you want...
 }

I think I like that idea better.  If you wanted to, you could make a subclass
with output_anchor_start as one of its methods, and put the ->watch_for 
stuff in the constructor.


=item * reading from filehandles

It would be nice if you could initialize an object by giving it a filehandle
or filename instead of the text itself.

=item * tests

I need to write a few tests that run under "make test".


=back


=head1 AUTHOR

Ken Williams <ken@forum.swarthmore.edu>

=head1 COPYRIGHT

Copyright 1998 Swarthmore College.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
