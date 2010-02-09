# More Custom Fields
# http://eatdrinksleepmovabletype.com/plugins/more_custom_fields/
# by Dan Wolfgang
# http://uinnovations.com

package MT::Plugin::MoreCustomFields;

use strict;
use warnings;
use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );

our $VERSION = '1.1.4';

my $plugin = __PACKAGE__->new({
    key             => 'morecustomfields',
    id              => 'morecustomfields',
    name            => 'More Custom Fields',
    description     => 'Use additional types of custom fields: checkbox group, radio buttons with an input box, and selected entries.',
    plugin_link     => 'http://eatdrinksleepmovabletype.com/plugins/more_custom_fields/',
    doc_link        => 'http://eatdrinksleepmovabletype.com/plugins/more_custom_fields/',
    author_name     => 'Dan Wolfgang, uiNNOVATIONS',
    author_link     => 'http://uinnovations.com/',
    version         => $VERSION,
});

MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        customfield_types => {
            checkbox_group => {
                label             => 'Checkbox Group',
                column_def        => 'vchar',
                order             => 301,
                no_default        => 1,
                options_delimiter => ',',
                options_field     => q{
        <div class="textarea-wrapper">
            <textarea name="options" id="options" class="full-width"><mt:Var name="options" escape="html"></textarea>
        </div>
        <p class="hint">
            Please enter all allowable options for this field as a comma delimited list.
        </p>
                }, # end of options_field
                field_html        => q{
        <ul class="custom-field-radio-list">
<mt:Loop name="option_loop">
    <mt:If name="option">
        <li>
            <mt:SetVarBlock name="optiontest"><mt:Var name="option"></mt:SetVarBlock>
            <input type="hidden" name="<mt:Var name="field_name">_checkboxgroupcf_<mt:Var name="__counter__">_cb_beacon" value="1" />
            <input type="checkbox" name="<mt:Var name="field_name">_checkboxgroupcf_<mt:Var name="__counter__">" value="<mt:Var name="option" escape="HTML">" id="<mt:Var name="field_id">_<mt:Var name="__counter__">"<mt:if name="field_value" like="$optiontest"> checked="checked"</mt:if> class="cb" />
            <label for="<mt:Var name="field_id">_<mt:Var name="__counter__">">
                <mt:Var name="option">
            </label>
        </li>
    </mt:If>
</mt:Loop>
        </ul>
                }, #end of field_html
            }, # end of checkbox_group customfield
            radio_input => {
                label             => 'Radio Buttons (with Input field)',
                column_def        => 'vchar',
                order             => 701,
                no_default        => 1,
                options_delimiter => ',',
                options_field     => q{
        <div class="textarea-wrapper">
            <textarea name="options" id="options" class="full-width"><mt:Var name="options" escape="html"></textarea>
        </div>
        <p class="hint">
            Please enter all allowable options for this field as a comma delimited list. The last option will have a text input option appended to it.
        </p>
                }, #options_field end
                field_html => q{
        <ul class="custom-field-radio-list">
<mt:Loop name="option_loop">
    <mt:If name="__last__">
        <li>
        <mt:Loop name="rbwi_input_loop">
            <mt:If name="field_id" like="$field_basename">
                <mt:If name="field_input" like=":">
                    <mt:Var name="field_input" escape="html" regex_replace='/^(.+?:\s+)(.+?)/',"$2" setvar="input">
                <mt:Else>
                    <mt:Var name="field_input" value="" setvar="input">
                </mt:If>
            </mt:if>
        </mt:loop>
        <mt:SetVarBlock name="label"><mt:Var name="option" escape="html"></mt:SetVarBlock>
            <input type="hidden" name="<mt:Var name="field_name">_radiobuttonswithinput_beacon" value="<mt:Var name="label" escape="html" regex_replace="/^(.*?):","$1">" />
            <input type="radio" name="<mt:Var name="field_name">" value="<mt:Var name="label" escape="html" regex_replace="/^(.*?):","$1">" id="<mt:Var name="field_id">_<mt:Var name="__counter__">"<mt:if name="input"> checked="checked"</mt:if> class="rb" />
            <label for="<mt:Var name="field_id">_<mt:Var name="__counter__">">
                <mt:Var name="label" escape="html">
            </label>
            <input type="text" name="<mt:Var name="field_name">_radiobuttonswithinput" style="border: 1px solid #ccc; margin-left: 5px;" value="<mt:Var name="input" escape="html">" />
        </li>
    <mt:Else>
        <li>
            <input type="radio" name="<mt:Var name="field_name">" value="<mt:Var name="option" escape="html">" id="<mt:Var name="field_id">_<mt:Var name="__counter__">"<mt:if name="is_selected"> checked="checked"</mt:if> class="rb" />
            <label for="<mt:Var name="field_id">_<mt:Var name="__counter__">">
                <mt:Var name="option" escape="html">
            </label>
        </li>
    </mt:If>
</mt:Loop>
        </ul>
                }, # field_html end
                field_html_params => sub {
                    my ($key, $tmpl_key, $tmpl_param) = @_;
                    my $app = MT->instance;

                    my $id       = $app->param('id');
                    my $blog     = $app->blog;
                    my $blog_id  = $blog ? $blog->id : 0;
                    my $obj_type = $tmpl_param->{obj_type};

                    # Figure out what kind of object we're working with
                    my @objects;
                    if ($obj_type eq 'author') {
                        @objects = MT::Author->load( { id => $id, } );
                    }
                    if ($obj_type eq 'category'){
                        @objects = MT::Category->load( { id => $id, } );
                    }
                    if ($obj_type eq 'folder'){
                        @objects = MT::Category->load( { id => $id, } );
                    }
                    if ($obj_type eq 'entry'){
                        @objects = MT::Entry->load( { id => $id, } );
                    }
                    if ($obj_type eq 'page'){
                        @objects = MT::Entry->load( { id => $id, } );
                    }

                    # Only one object should ever be returned (the current one)
                    # So I shouldn't really *need* to do a loop here... right?
                    foreach my $obj (@objects) {
                        my @fields = CustomFields::Field->load( { obj_type => $obj_type,
                        #Don't grab the blog_id because that keeps system-wide setting from working ok...
                                                                  #blog_id  => $blog_id,
                                                                  type     => 'radio_input',
                                                                } );
                        my @input_loop;
                        foreach my $field (@fields) {
                            my $basename = 'field.'.$field->basename;
                            # Throw these into a loop. That way, if multiple instances of
                            # the field are used, each gets the correct field and value.
                            push @input_loop, { field_basename => $field->basename,
                                                field_input    => $obj->$basename,
                                              };
                        }
                        $tmpl_param->{rbwi_input_loop} = \@input_loop;
                    }
                }, #field_html_params end
            }, # end of radio buttons w/ input customfield
            selected_entries => {
                label             => 'Selected Entries',
                column_def        => 'vchar',
                order             => 2000,
                no_default        => 1,
                options_delimiter => ',',
                options_field     => q{
        <div class="textarea-wrapper">
            <input name="options" id="options" class="full-width" value="<mt:Var name="options" escape="html">" />
        </div>
        <p class="hint">Enter the ID(s) of the blog(s) whose entries should be available for selection. Leave this field blank to use the current blog only.</p>
        <p class="hint">Blog IDs should be comma-separated (as in &rdquo;1,12,19,37,112&ldquo;), or the &rdquo;all&ldquo; value may be specified to include all blogs&rsquo; entries.</p>
                }, #options_field end
                field_html        => q{
<mt:SetVarBlock name="blogids"><mt:If name="options"><mt:Var name="options"><mt:Else><mt:Var name="blog_id"></mt:If></mt:SetVarBlock>
        <ul class="custom-field-selected-entries" id="custom-field-selected-entries_<mt:Var name="field_name">" style="margin-top: 3px;">
<mt:Loop name="selectedentries_loop">
        <li style="padding-bottom: 3px;" id="<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">">
        <mt:SetVarBlock name="selectedentry"><mt:Var name="field_selected"></mt:SetVarBlock>
            <select style="max-width: 550px;" name="<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">">
                <option value="0">None</option>
        <mt:Entries blog_ids="$blogids" sort="descend" lastn="9999">
                <option value="<mt:EntryID>"<mt:if tag="entryid" like="$selectedentry"> selected="selected"</mt:if>><mt:EntryTitle></option>
        </mt:Entries>
            </select><a style="padding: 3px 5px;" href="javascript:removeSelectedEntry('<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">');" title="Remove selected entry"><img src="<mt:StaticWebPath>images/status_icons/close.gif" width="9" height="9" alt="Remove selected entry" /></a>
        </li>
</mt:Loop>
        </ul>
        <p><a class="add-category-new-parent-link" href="javascript:addSelectedEntry('<mt:Var name="field_name">');">Add an entry</a></p>

                <select id="se-new-<mt:Var name="field_name">" style="display: none;">
                    <option value="0">None</option>
            <mt:Entries blog_ids="$blogids" sort="descend" lastn="9999">
                    <option value="<mt:EntryID>"><mt:EntryTitle></option>
            </mt:Entries>
                </select>

        <input type="hidden" id="se-adder-<mt:Var name="field_name">" value="1" />

        <script type="text/javascript">
        function addSelectedEntry(cf_name) {
            // Update the counter, so that each addition gets a unique number
            var adder_el = 'se-adder-' + cf_name;
            var numi = document.getElementById(adder_el);
            var num = (document.getElementById(adder_el).value -1) + 2;
            numi.value = num;

            // Create the select drop-down. Be sure to give it a unique name
            // (with the num from above) as well as remove the ID and style
            // so that it won't interfere with the original, which is used to
            // add more and more of these. Also note that newSelectName is used
            // here, in the delete link, and in the li id.
            var newSelectName = cf_name + '_selectedentriescf_new' + num;
            var new_el = 'se-new-' + cf_name;
            var newSelect = document.getElementById(new_el).cloneNode(true);
            newSelect.setAttribute('name', newSelectName);
            newSelect.removeAttribute('id');
            newSelect.setAttribute('style', 'max-width: 550px;');

            // Add the "delete" icon
            var newDeleteIcon = document.createElement('img');
            newDeleteIcon.setAttribute('src', '<mt:StaticWebPath>images/status_icons/close.gif');
            newDeleteIcon.setAttribute('width', '9');
            newDeleteIcon.setAttribute('height', '9');
            newDeleteIcon.setAttribute('alt', 'Remove selected entry');

            //Add the "delete" link
            var newDeleteLink = document.createElement('a');
            newDeleteLink.setAttribute('style', "margin-left: 5px;");
            newDeleteLink.setAttribute('style', 'padding: 3px 5px;');
            var href = "javascript:removeSelectedEntry('" + newSelectName + "');";
            newDeleteLink.setAttribute('href', href);
            newDeleteLink.setAttribute('title', 'Remove selected entry');
            newDeleteLink.appendChild(newDeleteIcon);

            // Create a new list item and add the new select drop-down to it.
            var newListItem = document.createElement('li');
            newListItem.setAttribute('id', newSelectName);
            newListItem.appendChild(newSelect);
            newListItem.appendChild(newDeleteLink);

            // Place the new list item in the drop-down selectors list.
            var CF = document.getElementById('custom-field-selected-entries_' + cf_name);
            CF.appendChild(newListItem);
        }
        function removeSelectedEntry(l) {
            var listItem = document.getElementById(l);
            listItem.parentNode.removeChild(listItem);
        }
        </script>
        <input type="hidden" name="<mt:Var name="field_name">_selectedentriescf_beacon" value=" " />
                }, #end of field_html
                field_html_params => sub {
                    my ($key, $tmpl_key, $tmpl_param) = @_;
                    my $app = MT->instance;

                    my $id       = $app->param('id');
                    my $blog     = $app->blog;
                    my $blog_id  = $blog ? $blog->id : 0;
                    my $obj_type = $tmpl_param->{obj_type};

                    my $field_name  = $tmpl_param->{field_name};

                    # Several dropdowns may be needed, because several entries were selected.
                    my $field_value = $tmpl_param->{field_value};
                    my @entryids = split(/,\s?/, $field_value);

                    my @entryids_loop;
                    foreach my $entryid (@entryids) {
                        # Verify that $entryid is a number. If no Selected Entries are found, 
                        # it's possible $entryid could be just a space character, which throws
                        # an error. So, this check ensures we always have a valid entry ID.
                        if ($entryid =~ m/\d+/) {
                            push @entryids_loop, { field_basename => $field_name,
                                                   field_selected => $entryid,
                                                 };
                        }
                    }
                    $tmpl_param->{selectedentries_loop} = \@entryids_loop;
                    
                }, #field_html_params end
            }, # end of selected_entries customfield
        },
        callbacks => {
            'api_post_save.entry' => { # For MTCS
                handler => \&_CMSPostSave,
                priority => 2,
            },
            'cms_post_save.entry' => {
                handler => \&_CMSPostSave,
                priority => 2,
            },
            'cms_post_save.page' => {
                handler => \&_CMSPostSave,
                priority => 2,
            },
            'cms_post_save.category' => {
                handler => \&_CMSPostSave,
                priority => 2,
            },
            'cms_post_save.folder' => {
                handler => \&_CMSPostSave,
                priority => 2,
            },
            'api_post_save.author' => { # For MTCS
                handler => \&_CMSPostSave,
                priority => 2,
            },
            'cms_post_save.author' => {
                handler => \&_CMSPostSave,
                priority => 2,
            }
        },
        tags => {
            block => {
                SelectedEntries => \&_selected_entries,
            },
        },
    });
}

sub _CMSPostSave {
    my ($cb, $app, $obj) = @_;
    return unless $app->isa('MT::App');

    foreach ($app->param) {
        # The "beacon" is used to always grab the checkboxes. After all are 
        # captured, then we can check their status (checked or not).
        if(m/^customfield_(.*?)_checkboxgroupcf_(.*?)_cb_beacon$/) { 
            my $count = $2;
            # Now look at the individual checkbox in the group to determine if 
            # it's checked.
            if( $app->param( /^customfield_(.*?)_checkboxgroupcf_$count$/ ) ) { 
                my $field_name = "customfield_$1_checkboxgroupcf_$count";
                
                # This line serves two purposes:
                # - Create the "real" customfield to write to the DB, if it doesn't exist already.
                # - If the field has already been created (because this is the 2nd or 3rd or 4th etc
                #   Checkbox Group CF option) then get it so that we can see the currently-selected
                #   options and append a new result to them.
                my $customfield_value = $app->param("customfield_$1");

                # Join all the checkboxes into a list
                my $result;
                if ( $customfield_value ) { #only "join" if the field has already been set
                    $result = join ', ', $customfield_value, $app->param($field_name);
                }
                else { # Nothing saved yet? Just assign the variable
                    $result = $app->param($field_name);
                }

                # If the customfield held some results, then a real text value exists, such as "blue."
                # If the field was empty, however, the $results variable is empty, indicating that the
                # field should *not* be saved. This is incorrect because an empty field may be
                # purposefully unselected, so we need to force save the deletion of the field.
                if (!$result) { $result = ' '; }

                # Save the new result to the *real* field name, which should be written to the DB.
                $app->param("customfield_$1", $result);

                # Destory the specially-assembled fields, because they make MT barf.
                $app->delete_param($field_name);
                $app->delete_param($field_name.'_cb_beacon');
            }
        }
        # Find the Radio Buttons with Input field.
        elsif (m/^customfield_(.*?)_radiobuttonswithinput$/) {
            my $field_name = "customfield_$1_radiobuttonswithinput";

            # This is the text input value
            my $input_value = $app->param($field_name);

            if ($input_value) {
                # The "beacon" is the name of the last field.
                my $selected = $app->param($field_name."_beacon");

                # This is the selected radio button
                my $customfield_value = $app->param("customfield_$1");

                # Compare the beacon and selected value. Only if they match should the text input be saved.
                if ($selected eq $customfield_value) {
                    $customfield_value .= ': '.$input_value;
                }

                $app->param("customfield_$1", $customfield_value);
            }

            # Destory the specially-assembled fields, because they make MT barf.
            $app->delete_param($field_name.'_beacon');
            $app->delete_param($field_name);
        }
        # Find the Selected Entries field.
        elsif( m/^customfield_(.*?)_selectedentriescf_(.*?)$/ ) {
            my $field_name = "customfield_$1_selectedentriescf_$2";
        
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

            # Save the new result to the *real* field name, which should be written to the DB.
            $app->param("customfield_$1", $result);

            # Destroy the specially-assembled fields, because they make MT barf.
            $app->delete_param($field_name);
        } #end of Selected Entries field.
    }
    1; # For some reason necessary to make author, category, and folder pages save without error.
}

sub _selected_entries {
    # The SelectedEntries tag will let you intelligently output the links you selected. Use:
    # <mt:SelectedEntries basename="selected_entries">
    #   <mt:If name="__first__">
    #     <ul>
    #   </mt:If>
    #     <li><a href="<mt:EntryPermalink>"><mt:EntryTitle></a></li>
    #   <mt:If name="__last__">
    #     </ul>
    #   </mt:If>
    # </mt:SelectedEntries>
    my ($ctx, $args, $cond) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $res     = '';

    # The basename of the custom field you want to grab must be specified.
    # It's used later, to load the field data.
    my $cf_basename = $args->{basename};
    if (!$cf_basename) {
        return $ctx->error( 'The SelectedEntries block tag requires the basename argument. The basename should be the Selected Entries Custom Fields field basename.' );
    }

    # Grab the field name with the collected data from above. The basename 
    # must be unique so it's a good thing to key off of!
    my $field = CustomFields::Field->load( { type     => 'selected_entries',
                                             basename => $cf_basename, } );
    if (!$field) { return $ctx->error('A Selected Entries Custom Field with this basename could not be found.'); }
    my $basename = 'field.'.$field->basename;
    my $obj_type = $field->obj_type;
    
    # Grab the correct object, based on the object type from the custom field.
    my $object;
    if ( $obj_type == 'entry' ) {
        $object = MT::Entry->load( { id => $ctx->stash('entry')->id, } );
    }
    elsif ( $obj_type == 'page' ) {
        # Entries and Pages are both stored in the mt_entry table
        $object = MT::Entry->load( { id => $ctx->stash('page')->id, } );
    }
    elsif ( $obj_type == 'category' ) {
        $object = MT::Category->load( { id => $ctx->stash('category')->id, } );
    }
    elsif ( $obj_type == 'folder' ) {
        # Categories and Folders are both stored in the mt_category table
        $object = MT::Category->load( { id => $ctx->stash('category')->id, } );
    }
    elsif ( $obj_type == 'author' ) {
        $object = MT::Author->load( { id => $ctx->stash('author')->id, } );
    }
    
    # Create an array of the entry IDs held in the field.
    # $object->$basename is the lookup that actually grabs the data.
    my @entryids = split(/,\s?/, $object->$basename);
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    foreach my $entryid (@entryids) {
        # Verify that $entryid is a number. If no Selected Entries are found, 
        # it's possible $entryid could be just a space character, which throws
        # an error. So, this check ensures we always have a valid entry ID.
        if ($entryid =~ m/\d+/) {
            # Assign the meta vars
            local $vars->{__first__} = !$i;
            local $vars->{__last__} = !defined $entryids[$i + 1];
            local $vars->{__odd__} = ($i % 2) == 0; # 0-based $i
            local $vars->{__even__} = ($i % 2) == 1;
            local $vars->{__counter__} = $i + 1;
            # Assign the selected entry
            my $entry = MT::Entry->load( { id => $entryid, } );
            local $ctx->{__stash}{entry} = $entry;

            my $out = $builder->build($ctx, $tokens);
            if (!defined $out) {
                # A error--perhaps a tag used out of context. Report it.
                return $ctx->error( $builder->errstr );
            }
            $res .= $out;
            $i++; # Increment for the meta vars.
        }
    }
    return $res;
}

1;

__END__
