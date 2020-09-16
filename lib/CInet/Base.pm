# ABSTRACT: The basis for computations on CI structures
package CInet::Base;

use Modern::Perl 2018;
use Import::Into;

sub import {
    CInet::Cube     -> import::into(1);
    CInet::Imset    -> import::into(1);
    CInet::Relation -> import::into(1);

    CInet::Seq       -> import::into(1);
    CInet::Seq::Map  -> import::into(1);
    CInet::Seq::Grep -> import::into(1);
    CInet::Seq::List -> import::into(1);
}

":wq"
