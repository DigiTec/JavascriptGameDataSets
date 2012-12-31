use strict;
use warnings;
use Data::Dumper;
use JSON;

my @files = qx(dir /s /b *.obj);

my %objs = ();
my %listTypes = (
    1 => { name => "Light",             values => ["unused", "unused", "capacity", "unused"] },
    2 => { name => "Scroll",            values => ["level", "spell 1", "spell 2", "spell 3"] },
    3 => { name => "Wand",              values => ["level", "capacity", "charge", "spell"] },
    4 => { name => "Staff",             values => ["level", "capacity", "charge", "spell"] },
    5 => { name => "Weapon",            values => ["unused", "dmgDieCount", "dmgDieSize", "weaponType"] },
    6 => { name => "FireWeapon",        values => ["unused", "unused", "unused", "unused"] },
    7 => { name => "Missile",           values => ["unused", "unused", "unused", "unused"] },
    8 => { name => "Treasure",          values => ["unused", "unused", "unused", "unused"] },
    9 => { name => "Armor",             values => ["acModifier", "unused", "unused", "unused"] },
    10 => { name => "Potion",           values => ["level", "spell 1", "spell 2", "spell 3"] },
    11 => { name => "Worn",             values => ["unused", "unused", "unused", "unused"] },
    12 => { name => "Other",            values => ["unused", "unused", "unused", "unused"] },
    13 => { name => "Trash",            values => ["unused", "unused", "unused", "unused"] },
    14 => { name => "Trap",             values => ["unused", "unused", "unused", "unused"] },
    15 => { name => "Container",        values => ["capacity", "flags", "keyObject", "reserved"] },
    16 => { name => "Note",             values => ["language", "unused", "unused", "unused"] },
    17 => { name => "DrinkContainer",   values => ["unused", "unused", "unused", "unused"] },
    18 => { name => "Key",              values => ["unused", "unused", "unused", "unused"] },
    19 => { name => "Food",             values => ["foodHours", "unused", "unused", "poisoned"] },
    20 => { name => "Money",            values => ["gold", "unused", "unused", "unused"] },
    21 => { name => "Pen",              values => ["unused", "unused", "unused", "unused"] },
    22 => { name => "Boat",             values => ["unused", "unused", "unused", "unused"] },
    23 => { name => "Fountain",         values => ["capacity", "charge", "effect", "poisoned"] }
);
my %listEffects = (
    a => "Glow",
    b => "Hum",
    c => "NORent",
    d => "NoDonate",
    e => "NoInvis",
    f => "Invisible",
    g => "Magic",
    h => "NoDrop",
    i => "Bless",
    j => "AntiGood",
    k => "AntiEvil",
    l => "AntiNeutral",
    m => "AntiMage",
    n => "AntiCleric",
    o => "AntiThief",
    p => "AntiWarrior",
    q => "NoSell"
);
my %listWearable = (
    a => "CanTake",
    b => "Finger",
    c => "Neck",
    d => "Body",
    e => "Head",
    f => "Legs",
    g => "Feet",
    h => "Hands",
    i => "Arms",
    j => "Shield",
    k => "Cloak",
    l => "Waist",
    m => "Wrist",
    n => "Wield",
    o => "Hold"
);
my @bitVectorWearable = (
    "CanTake", "Finger", "Neck", "Body",
    "Head", "Legs", "Feet", "Hands",
    "Arms", "Shield", "Cloak", "Waist",
    "Wrist", "Wield", "Hold"
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
            my $actionDesc = &ReadMultilineString(\*IN);
            my $traits = &ReadTraits(\*IN);
            my $typeValues = &ReadTypeValue(\*IN, $traits->{type});
            my $objectValue = &ReadObjectValue(\*IN);

            $objs{$vnum} = {
                aliases => $aliases,
                shortDesc => $shortDesc,
                longDesc => $longDesc,
                actionDesc => $actionDesc,
                wear => $traits->{wear},
                effects => $traits->{effects},
                type => $traits->{type}{name},
                typeValues => $typeValues,
                objectValue => $objectValue
            };
        }
    }
    close IN;
}

print to_json(\%objs, { utf8 => 1, pretty => 1});

sub ReadObjectValue($)
{
    my $fileHandle = shift;

    my $objValue = <$fileHandle>;
    chomp $objValue;

    my @objParts = split(/\s+/, $objValue);

    my %objectValue = (
        weight => int($objParts[0]),
        cost => int($objParts[1]),
        rentalCost => int($objParts[2])
    );
    return \%objectValue;
}

sub ReadTypeValue($$)
{
    my $fileHandle = shift;
    my $type = shift;

    my $typeValues = <$fileHandle>;
    chomp $typeValues;
    my @typeParts = split(/\s+/, $typeValues);

    my $value0 = int($typeParts[0]);
    my $value1 = int($typeParts[1]);
    my $value2 = int($typeParts[2]);
    my $value3 = int($typeParts[3]);

    # TODO: Some flag values such as spells, weapon damage type, etc...
    # need additional information to be complete. Serialize these additional values
    # as necessary.
    my %typeValues = ();
    if ($type->{values}[0] ne "unused" )
    {
        $typeValues{$type->{values}[0]} = $value0;
    }
    if ($type->{values}[1] ne "unused" )
    {
        $typeValues{$type->{values}[1]} = $value1;
    }
    if ($type->{values}[2] ne "unused" )
    {
        $typeValues{$type->{values}[2]} = $value2;
    }
    if ($type->{values}[3] ne "unused" )
    {
        $typeValues{$type->{values}[3]} = $value3;
    }
    return \%typeValues;
}

sub ReadTraits($)
{
    my $fileHandle = shift;

    my $value = <$fileHandle>;
    chomp $value;

    my @parts = split(/\s+/, $value);
    my %traits = (
        type => $listTypes{int($parts[0])},
        effects => {},
        wear => {}
    );

    my $effectValue = $parts[1];
    if ( $effectValue =~ /^\d+$/ )
    {
        my $effectBits = int($effectValue);
    }
    else
    {
        while(length($effectValue) > 0)
        {
            my $char = chop $effectValue;
            $traits{effects}{$listEffects{$char}} = 1;
        }
    }

    my $wearValue = $parts[2];
    if ( $wearValue =~ /^\d+$/ )
    {
        my $wearBits = int($wearValue);
        my $currentBit = 0;
        while($wearBits > 0)
        {
            if (($wearBits & 1) > 0) {
                $traits{wear}{$bitVectorWearable[$currentBit]} = 1;
            }
            $currentBit++;
            $wearBits = $wearBits >> 1;
        }
    }
    else
    {
        while(length($wearValue) > 0)
        {
            my $char = chop $wearValue;
            $traits{wear}{$listWearable{$char}} = 1;
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