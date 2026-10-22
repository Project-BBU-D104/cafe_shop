<?php

namespace App\Enums;

enum PaymentMethod: string
{
    case Cash = 'cash';
    case Card = 'card';
    case Qr = 'qr';
    case MobileWallet = 'mobile_wallet';
    case Other = 'other';
}
