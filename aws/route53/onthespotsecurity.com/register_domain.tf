
resource "aws_route53domains_domain" "domain" {
  domain_name = "onthespotsecurity.com"
  auto_renew  = true

  admin_contact {
    contact_type   = "PERSON"
    first_name     = "Jonathan"
    last_name      = "Case"
    email          = "jcase311@gmail.com"
    phone_number   = "+1.9082086452"
    address_line_1 = "30 Seabrook Rd"
    city           = "Stockton"
    state          = "NJ"
    country_code   = "US"
    zip_code       = "08559"
  }

  registrant_contact {
    contact_type   = "PERSON"
    first_name     = "Jonathan"
    last_name      = "Case"
    email          = "jcase311@gmail.com"
    phone_number   = "+1.9082086452"
    address_line_1 = "30 Seabrook Rd"
    city           = "Stockton"
    state          = "NJ"
    country_code   = "US"
    zip_code       = "08559"
  }

  tech_contact {
    contact_type   = "PERSON"
    first_name     = "Jonathan"
    last_name      = "Case"
    email          = "jcase311@gmail.com"
    phone_number   = "+1.9082086452"
    address_line_1 = "30 Seabrook Rd"
    city           = "Stockton"
    state          = "NJ"
    country_code   = "US"
    zip_code       = "08559"
  }
}
