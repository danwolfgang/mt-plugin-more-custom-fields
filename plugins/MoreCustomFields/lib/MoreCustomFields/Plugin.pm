package MoreCustomFields::Plugin;

use strict;
use warnings;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util qw( relative_date offset_time offset_time_list epoch2ts 
                 ts2epoch format_ts encode_html dirify );

use MoreCustomFields::CheckboxGroup;
use MoreCustomFields::RadioButtonsWithInput;
use MoreCustomFields::SelectedAssets;
use MoreCustomFields::SelectedEntriesOrPages;
use MoreCustomFields::SelectedEntries;
use MoreCustomFields::SelectedPages;
use MoreCustomFields::SingleLineTextGroup;
use MoreCustomFields::Message;
use MoreCustomFields::TimestampedTextarea;
use MoreCustomFields::ReciprocalObject;

sub init_app {
    my $plugin = shift;
    my ($app) = @_;
    return if $app->id eq 'wizard';

    my $r = $plugin->registry;
    my $tags = _load_tags( $app, $plugin );
    # If any tags were needed, merge them into the registry.
    if ( ref($tags) eq 'HASH' ) {
        MT::__merge_hash($r->{tags}, $tags);
    }
}

# Build the tags associated with all of these new fields, and return them to 
# the init_app callback.
sub _load_tags {
    my $app  = shift;
    my $tags = {};

    $tags = MoreCustomFields::SingleLineTextGroup::_create_tags({
        tags => $tags,
    });
    $tags = MoreCustomFields::TimestampedTextarea::_create_tags({
        tags => $tags,
    });

    return $tags;
}


sub load_customfield_types {
    my $customfield_types = {
        checkbox_group => {
            label             => 'Checkbox Group',
            column_def        => 'vchar',
            order             => 301,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::CheckboxGroup::_options_field(); },
            field_html        => sub { MoreCustomFields::CheckboxGroup::_field_html(); },
        },
        radio_input => {
            label             => 'Radio Buttons (with Input field)',
            column_def        => 'vchar',
            order             => 701,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::RadioButtonsWithInput::_options_field(); },
            field_html        => sub { MoreCustomFields::RadioButtonsWithInput::_field_html(); },
            field_html_params => sub { MoreCustomFields::RadioButtonsWithInput::_field_html_params(@_); },
        },
        selected_entries => {
            label             => 'Selected Entries',
            column_def        => 'vchar',
            order             => 2100,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SelectedEntries::_options_field(); },
            field_html        => sub { MoreCustomFields::SelectedEntries::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedObject::_field_html_params(@_); },
        },
        selected_pages => {
            label             => 'Selected Pages',
            column_def        => 'vchar',
            order             => 2101,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SelectedPages::_options_field(); },
            field_html        => sub { MoreCustomFields::SelectedPages::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedObject::_field_html_params(@_); },
        },
        selected_content => {
            label             => 'Selected Entries or Pages',
            column_def        => 'vchar',
            order             => 2102,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SelectedEntriesOrPages::_options_field(); },
            field_html        => sub { MoreCustomFields::SelectedEntriesOrPages::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedObject::_field_html_params(@_); },
        },
#        single_line_text_group => {
#            label             => 'Single-Line Text Group',
#            column_def        => 'vblob',
#            order             => 101,
#            no_default        => 1,
#            options_delimiter => ',',
#            options_field     => sub { MoreCustomFields::SingleLineTextGroup::_options_field(); },
#            field_html        => sub { MoreCustomFields::SingleLineTextGroup::_field_html(); },
#            field_html_params => sub { MoreCustomFields::SingleLineTextGroup::_field_html_params(@_); },
#        },
        multi_use_single_line_text_group => {
            label             => 'Multi-Use Single-Line Text Group',
            column_def        => 'vblob',
            order             => 102,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SingleLineTextGroup::_options_field(); },
            field_html        => sub { MoreCustomFields::SingleLineTextGroup::_multi_field_html(); },
            field_html_params => sub { MoreCustomFields::SingleLineTextGroup::_multi_field_html_params(@_); },
        },
        multi_use_timestamped_multi_line_text => {
            label             => 'Multi-Use Time Stamped Multi-Line Text',
            column_def        => 'vblob',
            order             => 201,
            no_default        => 1,
            field_html        => sub { MoreCustomFields::TimestampedTextarea::_field_html(); },
            field_html_params => sub { MoreCustomFields::TimestampedTextarea::_field_html_params(@_); },
        },
        message => {
            label             => 'Message',
            column_def        => 'vclob',
            order             => 210,
            # Disabling "no_default" means that a default *is* allowed.
            #no_default        => 1,
            options_field     => sub { MoreCustomFields::Message::_options_field(); },
            field_html        => sub { MoreCustomFields::Message::_field_html(); },
            field_html_params => sub { MoreCustomFields::Message::_field_html_params(@_); },
        },
        reciprocal_entry => {
            label             => 'Reciprocal Entry Association',
            column_def        => 'vchar',
            order             => 801,
            no_default        => 1,
            options_field     => sub { MoreCustomFields::ReciprocalObject::_options_field(); },
            field_html        => sub { MoreCustomFields::ReciprocalObject::_field_html('entry'); },
            field_html_params => sub { MoreCustomFields::ReciprocalObject::_field_html_params(@_,'entry'); },
        },
        reciprocal_page => {
            label             => 'Reciprocal Page Association',
            column_def        => 'vchar',
            order             => 802,
            no_default        => 1,
            options_field     => sub { MoreCustomFields::ReciprocalObject::_options_field(); },
            field_html        => sub { MoreCustomFields::ReciprocalObject::_field_html('page'); },
            field_html_params => sub { MoreCustomFields::ReciprocalObject::_field_html_params(@_,'page'); },
        },
    };

    # Grab all registered types of assets and add a new custom field for
    # each type. This way the field can be "Selected Images," for example
    # and give the user a chance to include only images and not other types
    # of assets.
    require MT::Asset;
    my $asset_types = MT::Asset->class_labels;
    my @asset_types =
      sort { $asset_types->{$a} cmp $asset_types->{$b} } keys %$asset_types;

    my $order = 2000;
    foreach my $a_type (@asset_types) {
        my $asset_type = $a_type;
        $asset_type =~ s/^asset\.//;

        # The $asset_type 'asset.file' returns a label of "Asset" for some
        # reason, so just correcct that here.
        my $label = ($asset_type eq 'file') 
          ? 'File' 
          : MT::Asset->class_handler($a_type)->class_label;
        $label = 'Selected '. $label . 's';

        $customfield_types->{'selected_' . $a_type . 's'} = {
            label             => $label,
            asset_type        => $a_type,
            no_default        => 1,
            column_def        => 'vchar',
            order             => $order,
            # Not setting the context (making the context system-wide)
            # results in a Selected Asset custom field that is usable at the
            # blog level as normal. However, when trying to use it for system-
            # level objects (authors), a a permissions error pops up. I
            # didn't investigate more because I don't need system-level
            # support.
            context           => 'blog',
            sanitize          => \&MT::Util::sanitize_asset,
            field_html        => sub { MoreCustomFields::SelectedAssets::_field_html(); },
            field_html_params => sub {
                # Add "asset_type" and "asset_type_label" to the template
                # parameters before going to _field_html_params.
                $_[2]->{asset_type} = $asset_type;
                $_[2]->{asset_type_label} = MT->translate($asset_type);
                MoreCustomFields::SelectedAssets::_field_html_params(@_); 
            },
        };
        # Increment $order so that each custom field has a unique position.
        $order += 1;
    }
    
    # $customfield_types now holds all the different asset types, as well
    # as the other custom field types defined above.
    return $customfield_types;
}

sub update_template {
    # This is responsible for loading jQuery in the head of the site.
    my ($cb, $app, $template) = @_;

    my $old = q{</head>};
    my $new;

    # Check if jQuery has already been loaded. If it has, just skip this.
    unless ( $$template =~ m/jquery/) {
        # Include jQuery as part of the js_include, used on the 
        # include/header.tmpl, which is used on all pages.
        $new = <<'END';
    <script type="text/javascript" src="<mt:StaticWebPath>jquery/jquery.js"></script>
END
    }

    # Insert the More Custom Fields javascript.
    $new .= <<'END';
    <script type="text/javascript" src="<mt:StaticWebPath>support/plugins/morecustomfields/jquery-ui-1.8.19.custom.min.js"></script>
    <script type="text/javascript" src="<mt:StaticWebPath>support/plugins/morecustomfields/app.js"></script>
    <link rel="stylesheet" type="text/css" href="<mt:StaticWebPath>support/plugins/morecustomfields/app.css" />
END

    $$template =~ s/$old/$new$old/;
}

sub post_save {
    my ($cb, $app, $obj) = @_;
    return unless $app->isa('MT::App');

    foreach ($app->param) {
        # The "beacon" is used to always grab the checkboxes. After all are 
        # captured, then we can check their status (checked or not).
        if(m/^customfield_(.*?)_checkboxgroupcf_(.*?)_cb_beacon$/) { 
            MoreCustomFields::CheckboxGroup::_save({
                app    => $app,
                object => $obj,
                count  => $2,
            });
        }
        # Find the Radio Buttons with Input field.
        elsif (m/^customfield_(.*?)_radiobuttonswithinput$/) {
            MoreCustomFields::RadioButtonsWithInput::_save({
                app            => $app,
                object         => $obj,
                field_basename => $1,
            });
        }
        # Find the Selected Assets or Selected Entries or Pages field.
        elsif( m/^customfield_(.*?)_selected(assets|content)cf_(.*?)$/ ) {
            my $field_name = $_;
            # This is the text input value
            my $input_value = $app->param($field_name);

            # This line serves two purposes:
            # - Create the "real" customfield to write to the DB, if it doesn't exist already.
            # - If the field has already been created (because this is the 2nd or 3rd or 4th etc
            #   Selected Entry CF option) then get it so that we can see the currently-selected
            #   options and append a new result to them.
            my $customfield_value = $app->param("customfield_$1");

            my $result;
            # Join all the selected entries into a list
            if ( $customfield_value ) { #only "join" if the field has already been set
                if ($input_value eq '0') {
                    $result = $customfield_value;
                }
                else {
                    $result = join ',', $customfield_value, $input_value;
                }
                $result =~ s/^\s?,(.*)$/$1/;
            }
            else { # Nothing saved yet? Just assign the variable
                $result = $app->param($field_name);
            }

            # If the customfield held some results, then a real EntryID value exists, such as "12."
            # If the field was empty, however, the $results variable is empty, indicating that the
            # field should *not* be saved. This is incorrect because an empty field may be
            # purposefully unselected, so we need to force save the deletion of the field.
            if (!$result) { $result = ' '; }

            # If all objects have been deleted, we need to save that this
            # field is now empty. To do this, we still need something to
            # check for: a beacon. After the last Selected Asset/Entry/Page
            # has been deleted, a beacon hidden input field is inserted.
            # Check for this field. If it exists, then remove clear any
            # saved data.
            if ($3 eq 'beacon') {
                $result = ' ';
            }

            # Save the new result to the *real* field name, which should be written to the DB.
            $app->param("customfield_$1", $result);

            # Destroy the specially-assembled fields, because they make MT barf.
            $app->delete_param($field_name);
        } #end of Selected Entries/Pages/Assets field.

        # Find the Multi-Use Single Line Text Group field
        # The "beacon" is used to always grab the text field. This will catch
        # an empty text field.
        elsif (m/^customfield_(.*?)_multiusesinglelinetextgroupcf_(.*?)_cb_beacon$/) {
            MoreCustomFields::SingleLineTextGroup::_save({
                app             => $app,
                object          => $obj,
                user_field_name => $2,
            });
        }

        # Find the Multi-Use Time Stamped Multi-Line Text Group field
        # The "beacon" is used to always grab the text field. This will catch
        # an empty text field.
        elsif (m/^customfield_(.*?)_multiusetimestampedmultilinetextcf_cb_beacon$/) {
            MoreCustomFields::TimestampedTextarea::_save({
                app            => $app,
                object         => $obj,
                field_basename => $1,
            });
        }

        # Find the Reciprocal Entry Association field.
        elsif (m/^customfield_(.*?)_reciprocal_(entry|page)$/) {
            MoreCustomFields::ReciprocalObject::_save({
                app            => $app,
                object         => $obj,
                field_basename => $1,
            });
        }
    }
    
    1; # Callbacks should always return true
}

1;

__END__
