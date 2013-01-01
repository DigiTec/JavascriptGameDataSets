use JSON;
use Data::Dumper;
my ($inputFile, $outputFileTrie, $outputFileArray) = (@ARGV);

my %wordTrie = (
    totalWords => 0
);
my @wordArray = ();

open IN, "<$inputFile";
while(<IN>)
{
    chomp;
    my $word = lc;
    if ( /^[a-z]+$/ && length($_) >= 3)
    {
        push @wordArray, $_;
        $wordTrie{totalWords}++;

        my $word = $_;
        my $prefix = substr($word, 0, 3, "");
        my $hashLevel = \%wordTrie;
        if (!defined $hashLevel->{$prefix})
        {
            $hashLevel->{$prefix} = {};
        }
        $hashLevel = $hashLevel->{$prefix};

        while(length($word) > 0)
        {
            my $char = substr($word, 0, 1, "");
            if (!defined $hashLevel->{$char})
            {
                $hashLevel->{$char} = {};
            }

            $hashLevel = $hashLevel->{$char};
        }

        # declare this as a terminal in the sequence
        $hashLevel->{1} = 1;
    }
    else
    {
        # print "Filtering $_\n";
    }
}
close IN;

open OUT, ">$outputFileTrie";
print OUT to_json(\%wordTrie, { utf8 => 1 });
close OUT;

open OUT, ">$outputFileArray";
print OUT to_json(\@wordArray, { utf8 => 1 });
close OUT;