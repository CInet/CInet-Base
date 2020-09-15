package CInet::Base;

use Modern::Perl 2018;
use Import::Into;

sub import {
    CInet::Cube     -> import::into(1);
    CInet::Imset    -> import::into(1);
    CInet::Relation -> import::into(1);
    CInet::Results  -> import::into(1);

    CInet::Results::Map  -> import::into(1);
    CInet::Results::Grep -> import::into(1);
    CInet::Results::List -> import::into(1);
}

":wq"
