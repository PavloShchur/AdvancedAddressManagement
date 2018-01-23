global without sharing class CountryServices {

    public static Map<String, String> codeToCountry = new Map<String, String>{
        'AD' => 'Andorra',
        'AU' => 'Australia',
        'AT' => 'Austria',
        'AZ' => 'Azerbaijan',
        'BS' => 'Bahamas',
        'BH' => 'Bahrain',
        'BB' => 'Barbados',
        'BE' => 'Belgium',
        'BM' => 'Bermuda',
        'BA' => 'Bosnia and Herzegovina',
        'BW' => 'Botswana',
        'BR' => 'Brazil',
        'BG' => 'Bulgaria',
        'CA' => 'Canada',
        'KY' => 'Cayman Islands',
        'CL' => 'Chile',
        'CN' => 'China',
        'CO' => 'Colombia',
        'CR' => 'Costa Rica',
        'HR' => 'Croatia',
        'CZ' => 'Czech Republic',
        'DK' => 'Denmark',
        'EG' => 'Egypt',
        'EE' => 'Estonia',
        'FK' => 'Falkland Islands',
        'FI' => 'Finland',
        'FR' => 'France',
        'PF' => 'French Polynesia',
        'DE' => 'Germany',
        'GH' => 'Ghana',
        'GR' => 'Greece',
        'GG' => 'Guernsey',
        'HK' => 'Hong Kong',
        'HU' => 'Hungary',
        'IS' => 'Iceland',
        'IN' => 'India',
        'ID' => 'Indonesia',
        'IE' => 'Ireland',
        'IM' => 'Isle Of Man',
        'IL' => 'Israel',
        'IT' => 'Italy',
        'JP' => 'Japan',
        'JE' => 'Jersey',
        'JO' => 'Jordan',
        'KZ' => 'Kazakhstan',
        'XK' => 'Kosovo',
        'KW' => 'Kuwait',
        'LV' => 'Latvia',
        'LB' => 'Lebanon',
        'LY' => 'Libya',
        'LI' => 'Liechtenstein',
        'LT' => 'Lithuania',
        'LU' => 'Luxembourg',
        'MY' => 'Malaysia',
        'MT' => 'Malta',
        'MU' => 'Mauritius',
        'MX' => 'Mexico',
        'MC' => 'Monaco',
        'MA' => 'Morocco',
        'MZ' => 'Mozambique',
        'NL' => 'Netherlands',
        'NC' => 'New Caledonia',
        'NZ' => 'New Zealand',
        'NG' => 'Nigeria',
        'NO' => 'Norway',
        'OM' => 'Oman',
        'PK' => 'Pakistan',
        'PA' => 'Panama',
        'PE' => 'Peru',
        'PH' => 'Philippines',
        'PL' => 'Poland',
        'PT' => 'Portugal',
        'QA' => 'Qatar',
        'RO' => 'Romania',
        'RU' => 'Russia',
        'SM' => 'San Marino',
        'SA' => 'Saudi Arabia',
        'RS' => 'Serbia',
        'SG' => 'Singapore',
        'SK' => 'Slovakia',
        'SI' => 'Slovenia',
        'ZA' => 'South Africa',
        'KR' => 'South Korea',
        'ES' => 'Spain',
        'SE' => 'Sweden',
        'CH' => 'Switzerland',
        'TW' => 'Taiwan',
        'TH' => 'Thailand',
        'TT' => 'Trinidad & Tobago',
        'TN' => 'Tunisia',
        'TR' => 'Turkey',
        'AE' => 'United Arab Emirates',
        'GB' => 'United Kingdom',
        'US' => 'United States',
        'UY' => 'Uruguay',
        'VN' => 'Vietnam',
        'VG' => 'Virgin Islands (British)',
        'ZM' => 'Zambia',

        'AF' => 'Afghanistan',
        'AL' => 'Albania',
        'DZ' => 'Algeria',
        'AO' => 'Angola',
        'AI' => 'Anguilla',
        'AG' => 'Antigua and Barbuda',
        'AR' => 'Argentina',
        'AM' => 'Armenia',
        'AW' => 'Aruba',
        'BD' => 'Bangladesh',
        'BY' => 'Belarus',
        'BZ' => 'Belize',
        'BJ' => 'Benin',
        'BO' => 'Bolivia',
        'BN' => 'Brunei',
        'BF' => 'Burkina Faso',
        'MM' => 'Burma (Myanmar)',
        'BI' => 'Burundi',
        'KH' => 'Cambodia',
        'CM' => 'Cameroon',
        'CF' => 'Central African Republic',
        'TD' => 'Chad',
        'GI' => 'Gilbraltar',
        'KM' => 'Comoros',
        'CD' => 'Congo, Democratic Republic ',
        'CK' => 'Cook Islands',
        'CW' => 'Curacao',
        'CY' => 'Cyprus',
        'DJ' => 'Djibouti',
        'DO' => 'Dominican Republic',
        'EC' => 'Ecuador',
        'SV' => 'El Salvador',
        'GQ' => 'Equatorial Guinea',
        'ER' => 'Eritrea',
        'ET' => 'Ethiopia',
        'FO' => 'Faroe Islands',
        'FJ' => 'Fiji',
        'GA' => 'Gabon',
        'GM' => 'Gambia',
        'GE' => 'Georgia',
        'GD' => 'Grenada',
        'GT' => 'Guatemala',
        'GW' => 'Guinea-Bissau',
        'GY' => 'Guyana',
        'HT' => 'Haiti',
        'HN' => 'Honduras',
        'IQ' => 'Iraq',
        'CI' => 'Ivory Coast',
        'JM' => 'Jamaica',
        'KE' => 'Kenya',
        'KI' => 'Kiribati',
        'KG' => 'Kyrgyzstan',
        'LA' => 'Laos',
        'LS' => 'Lesotho',
        'LR' => 'Liberia',
        'MO' => 'Macau',
        'MK' => 'Macedonia',
        'MG' => 'Madagascar',
        'MW' => 'Malawi',
        'MV' => 'Maldives',
        'ML' => 'Mali',
        'MH' => 'Marshall Islands',
        'MR' => 'Mauritania',
        'MN' => 'Mongolia',
        'ME' => 'Montenegro',
        'NA' => 'Namibia',
        'NP' => 'Nepal',
        'NI' => 'Nicaragua',
        'NE' => 'Niger',
        'NF' => 'Norfolk Islands',
        'PG' => 'Papua New Guinea',
        'PY' => 'Paraguay',
        'GN' => 'Republic of Guinea',
        'RW' => 'Rwanda',
        'WS' => 'Samoa',
        'ST' => 'Sao Tome and Principe',
        'SN' => 'Senegal',
        'SC' => 'Seychelles',
        'SL' => 'Sierra Leone',
        'SB' => 'Solomon Islands',
        'SO' => 'Somalia',
        'LK' => 'Sri Lanka',
        'KN' => 'St. Kitts and Nevis',
        'LC' => 'St Lucia',
        'VC' => 'St Vincent & Grenadine',
        'SS' => 'Sudan South',
        'SZ' => 'Swaziland',
        'TJ' => 'Tajikstan',
        'TZ' => 'Tanzania',
        'TL' => 'Timor-Leste (East Timor)',
        'TG' => 'Togo',
        'TM' => 'Turkmenistan',
        'TC' => 'Turks and Caicos Islands',
        'TV' => 'Tuvalu',
        'UG' => 'Uganda',
        'UA' => 'Ukraine',
        'UZ' => 'Uzbekistan',
        'VU' => 'Vanuatu',
        'VE' => 'Venezuela',
        'YE' => 'Yemen',
        'ZW' => 'Zimbabwe'
    };

    public static Map<String, String> countryIsoCodeToName {
        get {
            if( countryIsoCodeToName == null ) {
                countryIsoCodeToName = new Map<String, String>();
                for( Country_Mapping__c countryMapping : [ SELECT Iso_Code__c, Country_Name__c
                                                           FROM Country_Mapping__c ] ) {
                    countryIsoCodeToName.put( countryMapping.Iso_Code__c, countryMapping.Country_Name__c );
                }
            }
            return countryIsoCodeToName;
        }
        private set;
    }

    global static void recreateCountryMappings() {
        List<Country_Mapping__c> oldCountries = [ SELECT Id
                                                  FROM Country_Mapping__c
                                                  WHERE Iso_Code__c IN :codeToCountry.keySet() ];
        DELETE oldCountries;
        List<Country_Mapping__c> newCountries = new List<Country_Mapping__c>();
        for( String isoCode : codeToCountry.keySet() ) {
            newCountries.add(
                new Country_Mapping__c(
                    Iso_Code__c = isoCode,
                    Country_Name__c = codeToCountry.get( isoCode )
                )
            );
        }
        INSERT newCountries;
    }

    public static void populateCountryMapping( List<Address__c> addresses ) {
        List<Address__c> addressesWithCountries = new List<Address__c>();
        Map<String, Id> isoCodeToCountryMappingId = new Map<String, Id>();
        for( Address__c address : addresses ) {
            if( address.Country__c == null ) {
                address.Country_Mapping__c = null;
            } else {
                addressesWithCountries.add( address );
                isoCodeToCountryMappingId.put( address.Country__c, null );
            }
        }
        if( addressesWithCountries.isEmpty() ) return;
        for( Country_Mapping__c mapping : [ SELECT Iso_Code__c, Country_Name__c
                                            FROM Country_Mapping__c
                                            WHERE Iso_Code__c IN :isoCodeToCountryMappingId.keySet() ] ) {
            isoCodeToCountryMappingId.put( mapping.Iso_Code__c, mapping.Id );
        }
        for( Address__c address : addressesWithCountries ) {
            address.Country_Mapping__c = isoCodeToCountryMappingId.get( address.Country__c ) != null ? isoCodeToCountryMappingId.get( address.Country__c ) : null;
        }
    }

    public static void populateCountryMappingsOnAddress( List<Country_Mapping__c> newList ) {
        Map<String, Id> isoCodeToCountryMappingId = new Map<String, Id>();
        for( Country_Mapping__c countryMapping : newList ) {
            isoCodeToCountryMappingId.put( countryMapping.Iso_Code__c, countryMapping.Id );
        }
        List<Address__c> addressesToUpdate = [ SELECT Country__c
                                               FROM Address__c
                                               WHERE Country__c IN :isoCodeToCountryMappingId.keySet() ];
        for( Address__c address : addressesToUpdate ) {
            address.Country_Mapping__c = isoCodeToCountryMappingId.get( address.Country__c );
        }
        UPDATE addressesToUpdate;
    }

}