# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::SimpleParse;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub report_result {
	my $ok = shift;
	$TEST_NUM ||= 2;
	print "not " unless $ok;
	print "ok $TEST_NUM\n";
	
	print @_ if (not $ok and $ENV{TEST_VERBOSE});
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
	&report_result(($hash{A} eq "xx" and exists $hash{B} and $hash{C} eq "hi"),
	               "$hash{A} eq xx and exists $hash{B} (". exists($hash{B}). ") and $hash{C} eq hi\n");
}

# 5
{
	my $text = 'type=checkbox checked name=flavor value="chocolate or strawberry"';
	my %hash = HTML::SimpleParse->parse_args( $text );
	&report_result(($hash{TYPE} eq "checkbox" and exists $hash{CHECKED} and 
	                $hash{VALUE} eq "chocolate or strawberry"),
	               "$hash{TYPE} eq checkbox and exists (". exists($hash{CHECKED}) .") and 
	                $hash{VALUE} eq 'chocolate or strawberry'");
}

# 6
{
	my %hash=HTML::SimpleParse->parse_args(' A="xx" B');
	&report_result(($hash{A} eq 'xx' and exists $hash{B}),
	               "$hash{A} eq 'xx' and \$hash{B}, (". exists($hash{B}) .")\n");
}

# 7
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

# 8
{
	my %hash = HTML::SimpleParse->parse_args('a="b=c"');
	&report_result($hash{A} eq "b=c", "hash: @{[ %hash ]}\n");
}

# 9
{
	my %hash = HTML::SimpleParse->parse_args('val="a \"value\""');
	&report_result($hash{VAL} eq 'a "value"', "value: $hash{VAL}\n");
}

# 10
{
  my %hash = HTML::SimpleParse->parse_args('val = "a \"value\""');
  &report_result($hash{VAL} eq 'a "value"', "value: $hash{VAL}\n");
}

# 11
{
  # Avoid 'uninitialized value' warning
  my $ok=1;
  local $^W=1;
  local $SIG{__WARN__} = sub {$ok=0};
  HTML::SimpleParse->new();
  &report_result($ok);
}

# 12
{
  my %hash = HTML::SimpleParse->parse_args("val='a value'");
  &report_result($hash{VAL} eq 'a value', "value: $hash{VAL}\n");
}

# 13
{
  local $HTML::SimpleParse::FIX_CASE = 0;
  my %hash = HTML::SimpleParse->parse_args("val='a value'");
  &report_result($hash{val} eq 'a value', "value: $hash{val}\n");
}

# 14
{
  local $HTML::SimpleParse::FIX_CASE = 0;
  my %hash = HTML::SimpleParse->parse_args("Val='a value'");
  &report_result($hash{Val} eq 'a value', "value: $hash{Val}\n");
}

# 15
{
  my $p = new HTML::SimpleParse('', fix_case => 0);
  my %hash = $p->parse_args("Val='a value'");
  &report_result($hash{Val} eq 'a value', "value: $hash{Val}\n");
}

# 16: offset
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
  my $p = new HTML::SimpleParse($text);
  my $ok = 1;
  foreach ($p->tree) {
    $ok = 0 unless substr($text, $_->{offset}) =~ /^<?\Q$_->{content}/;
  }
  print $ok ? "ok 16\n" : "not ok 16\n";
}
