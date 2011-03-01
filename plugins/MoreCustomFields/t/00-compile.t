use lib 't/lib', 'lib', 'extlib';

use MT::Test;
use Test::More tests => 11;

ok( MT->component('MoreCustomFields'), "MoreCustomFields loaded" );

# require_ok('RelatedItems::Plugin');
require_ok('MoreCustomFields::Plugin');
require_ok('MoreCustomFields::Message');
require_ok('MoreCustomFields::CheckboxGroup');
require_ok('MoreCustomFields::RadioButtonsWithInput');
require_ok('MoreCustomFields::SelectedContent');
require_ok('MoreCustomFields::SelectedEntries');
require_ok('MoreCustomFields::SelectedPages');
require_ok('MoreCustomFields::SelectedAssets');
require_ok('MoreCustomFields::SingleLineTextGroup');
require_ok('MoreCustomFields::Plugin');
# require_ok('RelatedItems::Tags');
