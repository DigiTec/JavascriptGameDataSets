use strict;
use warnings;
use Data::Dumper;
use JSON;

my @files = qx(dir /s /b *.mob);

my %mobs = ();
my %listPositions = (
    "0" => "Dead",
    "1" => "MortallyWounded",
    "2" => "Incapacitated",
    "3" => "Stunned",
    "4" => "Sleeping",
    "5" => "Resting",
    "6" => "Sitting",
    "7" => "Fighting",
    "8" => "Standing"
);
my %listSex = (
    "0" => "Neutral",
    "1" => "Male",
    "2" => "Female"
);
my %listActions = (
    a => "SPEC",
    b => "SENTINEL",
    c => "SCAVENGER",
    d => "ISNPC",
    e => "AWARE",
    f => "AGGRESSIVE",
    g => "STAY_ZONE",
    h => "WIMPY",
    i => "AGGR_EVIL",
    j => "AGGR_GOOD",
    k => "AGGR_NEUTRAL",
    l => "MEMORY",
    m => "HELPER",
    n => "NOCHARM",
    o => "NOSUMMON",
    p => "NOSLEEP",
    q => "NOBASH",
    r => "NOBLIND",
    s => "NOTDEADYET"
);
my %listAffections = (
    a => "BLIND",
    b => "INVISIBLE",
    c => "DETECT_ALIGN",
    d => "DETECT_INVIS",
    e => "DETECT_MAGIC",
    f => "SENSE_LIFE",
    g => "WATERWALK",
    h => "SANCTUARY",
    i => "GROUP",
    j => "CURSE",
    k => "INFRAVISION",
    l => "POISON",
    m => "PROTECT_EVIL",
    n => "PROTECT_GOOD",
    o => "SLEEP",
    p => "NOTRACK",
    q => "UNUSED_Q",
    r => "UNUSED_R",
    s => "SNEAK",
    t => "HIDE",
    u => "UNUSED_U",
    v => "CHARM"
);

for my $file (@files) {
    open IN, "<$file";
    while(<IN>) {
        chomp;
        if ( /^#(\d+)/ ) {
            my $vnum = $1;
            my $aliases = &ReadAliasList(\*IN);
            my $shortDesc = &ReadMultilineString(\*IN);
            my $longDesc = &ReadMultilineString(\*IN);
            my $detailedDesc = &ReadMultilineString(\*IN);
            my $traits = &ReadTraits(\*IN);
            my $typeSMob = &ReadTypeSMob(\*IN);

            $mobs{$vnum} = {
                aliases => $aliases,
                shortDesc => $shortDesc,
                longDesc => $longDesc,
                detailedDesc => $detailedDesc,
                traits => $traits,
                typeSMob => $typeSMob
            };

            if ($traits->{type} eq 'E')
            {
                my $typeEMob = &ReadTypeEMob(\*IN);
                $mobs{$vnum}{typeEMob} = $typeEMob;
            }
        }
    }
    close IN;
}

# print Dumper(\%mobs);
print to_json(\%mobs, { utf8 => 1, pretty => 1});

sub ReadTypeEMob($)
{
    my $fileHandle = shift;
    my @typeEMob = ();
    while(<$fileHandle>)
    {
        chomp;
        if (/^E$/) {
            last;
        }
        my @parts = split(/:/, $_);
        push @typeEMob, { trait => $parts[0], value => $parts[1] };
    }
    return \@typeEMob;
}

sub ReadTypeSMob($)
{
    my $fileHandle = shift;
    my $levelValue = <$fileHandle>;
    my $goldValue = <$fileHandle>;
    my $loadValue = <$fileHandle>;

    chomp $levelValue;
    chomp $goldValue;
    chomp $loadValue;

    my @levelParts = split(/\s+/, $levelValue);
    my @goldParts = split(/\s+/, $goldValue);
    my @loadParts = split(/\s+/, $loadValue);
    my %typeSMob = (
        level => int($levelParts[0]),
        thac0 => int($levelParts[1]),
        ac => int($levelParts[2]),
        hitDie => $levelParts[3],
        bhDie => $levelParts[4],
        gold => int($goldParts[0]),
        exp => int($goldParts[1]),
        startPos => $listPositions{$loadParts[0]},
        defaultPos => $listPositions{$loadParts[1]},
        sex => $listSex{$loadParts[2]}
    );
    return \%typeSMob;
}

sub ReadTraits($)
{
    my $fileHandle = shift;

    my $value = <$fileHandle>;
    chomp $value;

    my @parts = split(/\s+/, $value);
    my %traits = (
        actions => {},
        affections => {},
        alignment => int($parts[2]),
        type => $parts[3]
    );

    my $actionValue = $parts[0];
    if ( $actionValue =~ /^\d+$/ )
    {
        my $actionBits = int($actionValue);
    }
    else
    {
        while(length($actionValue) > 0)
        {
            my $char = chop $actionValue;
            $traits{actions}{$listActions{$char}} = 1;
        }
    }

    my $affValue = $parts[0];
    if ( $affValue =~ /^\d+$/ )
    {
        my $actionBits = int($affValue);
    }
    else
    {
        while(length($affValue) > 0)
        {
            my $char = chop $affValue;
            if (!defined $listAffections{$char}) {
                die "$char\n";
            }
            $traits{affections}{$listAffections{$char}} = 1;
        }
    }
    return \%traits;
}

sub ReadAliasList($)
{
    my $fileHandle = shift;
    my $value = &ReadMultilineString($fileHandle);
    my @array = split(/\s+/, $value);
    return \@array;
}

sub ReadMultilineString($)
{
    my $fileHandle = shift;
    my @values = ();
    while(<$fileHandle>) {
        chomp;
        if (/\~$/) {
            chop;
            push @values, $_;
            last;
        }
        push @values, $_;
    }
    return join(' ', @values);
}