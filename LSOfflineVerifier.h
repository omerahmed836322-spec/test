#pragma once
// Salted PBKDF2 verifier; no plaintext activation code.
static const unsigned char LSOfflineSalt[] = {10,233,55,9,22,40,55,190,199,186,184,255,203,112,183,45,72,241,252,106,63,39,78,254};
static const unsigned char LSOfflineDigest[] = {7,144,194,180,29,233,254,159,138,122,94,43,18,33,191,61,35,189,30,200,203,225,17,69,216,134,25,206,220,35,98,4};
static const unsigned int LSOfflineRounds = 120000;
