# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::SimpleParse;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub report_result {
	$TEST_NUM ||= 2;
	print "not " unless $_[0];
	print "ok $TEST_NUM\n";
	
	print $_[1] if (not $_[0] and $ENV{TEST_VERBOSE});
	$TEST_NUM++;
}
	 

# 2
{
	my %hash = HTML::SimpleParse->parse_args('A="xx" B=3');
	&report_result($hash{A} eq "xx" and $hash{B} eq 3);
}

# 3
{
	my %hash = HTML::SimpleParse->parse_args('A="xx" B');
	&report_result($hash{A} eq "xx" and exists $hash{B});
}

# 4
{
	my %hash = HTML::SimpleParse->parse_args('A="xx" B c="hi" ');
	&report_result(($hash{A} eq "xx" and exists $hash{B} and $hash{c} eq "hi"),
	               "$hash{A} eq xx and exists $hash{B} (". exists($hash{B}). ") and $hash{c} eq hi\n");
}

# 5
{
	my $text = 'type=checkbox checked name=flavor value="chocolate or strawberry"';
	my %hash = HTML::SimpleParse->parse_args( $text );
	&report_result(($hash{type} eq "checkbox" and exists $hash{checked} and 
	                $hash{value} eq "chocolate or strawberry"),
	               "$hash{type} eq checkbox and exists (". exists($hash{checked}) .") and 
	                $hash{value} eq 'chocolate or strawberry'");
}

# 7
{
	my %hash=HTML::SimpleParse->parse_args(' A="xx" B');
	&report_result(($hash{A} eq 'xx' and exists $hash{B}),
	               "$hash{A} eq 'xx' and \$hash{B}, (". exists($hash{B}) .")\n");
}

# 6
{
	my $text = <<EOF;
	<html><head>
	<title>Hiya, tester</title>
	</head>
	
	<body>
	<center><h1>Hiya, tester</h1></center>
	<!-- here is a comment -->
	<!DOCTYPE here is a markup>
	<!--# here is an ssi -->
	</body>
	</html>
EOF
	my $p = new HTML::SimpleParse( $text );
	
	&report_result($p->get_output() eq $text, $p->get_output);

}

