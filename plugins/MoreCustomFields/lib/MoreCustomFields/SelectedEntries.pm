package MoreCustomFields::SelectedEntries;

use strict;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util
  qw( relative_date offset_time offset_time_list epoch2ts ts2epoch format_ts encode_html dirify );

sub _options_field {
    return q{
<div class="textarea-wrapper">
    <input name="options" id="options" class="full-width" value="<mt:Var name="options" escape="html">" />
</div>
<p class="hint">Enter the ID(s) of the blog(s) whose entries should be available for selection. Leave this field blank to use the current blog only.</p>
<p class="hint">Blog IDs should be comma-separated (as in &rdquo;1,12,19,37,112&ldquo;), or the &rdquo;all&ldquo; value may be specified to include all blogs&rsquo; entries.</p>
    };
}

sub _field_html {
    return q{
<script type="text/javascript">
    function insertSelectedEntry(html, val, id) {
        var se = document.getElementById(id);
        se.setAttribute('value', val);

        var se_preview_id = id + '_preview';
        document.getElementById(se_preview_id).innerHTML = html;
    }
</script>

<mt:SetVarBlock name="blogids"><mt:If name="options"><mt:Var name="options"><mt:Else><mt:Var name="blog_id"></mt:If></mt:SetVarBlock>

<ul class="custom-field-selected-entries" id="custom-field-selected-entries_<mt:Var name="field_name">" style="margin-top: 3px;">
<mt:Loop name="selectedentries_loop">
    <li style="padding-bottom: 3px;" id="li_<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">">
        <mt:SetVarBlock name="selectedentry"><mt:Var name="field_selected"></mt:SetVarBlock>
        <input name="<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">" id="<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">" class="hidden" type="hidden" value="<mt:Var name="field_selected">" />
        <button
            style="background: #333 url('<mt:StaticWebPath>images/buttons/button.gif') no-repeat 0 center; border:none; border-top:1px solid #d4d4d4; font-weight: bold; font-size: 14px; line-height: 1.3; text-decoration: none; color: #eee; cursor: pointer; padding: 2px 10px 4px;"
            type="submit"
            onclick="return openDialog(this.form, 'mcf_list_entries', 'blog_id=<mt:Var name="blogids">&edit_field=<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">')">
            Choose Entry
        </button>
        <span id="<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">_preview" class="preview" style="padding-left: 8px;">
            <mt:Entries blog_ids="$blogids" lastn="999999" id="$selectedentry">
                <mt:EntryTitle>
            </mt:Entries>
        </span>
        <a style="padding: 3px 5px;" href="javascript:removeSelectedEntry('li_<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">','<mt:Var name="field_name">');" title="Remove selected entry"><img src="<mt:StaticWebPath>images/status_icons/close.gif" width="9" height="9" alt="Remove selected entry" /></a>
    </li>
</mt:Loop>
</ul>
<p><a class="add-category-new-parent-link" href="javascript:addSelectedEntry('<mt:Var name="field_name">', '<mt:Var name="blogids">');">Add an entry</a></p>

    <input id="se-new-input-<mt:Var name="field_name">" style="display: none;" class="hidden" type="hidden" />
    <button
        style="display: none;"
        id="se-new-button-<mt:Var name="field_name">"
        type="submit">
        Choose Entry
    </button>
    <span id="se-new-preview-<mt:Var name="field_name">" class="preview" style="display: none;">
    </span>


<input type="hidden" id="se-adder-<mt:Var name="field_name">" value="1" />

<script type="text/javascript">
    function addSelectedEntry(cf_name, blog_ids) {
        // Update the counter, so that each addition gets a unique number
        var adder_el = 'se-adder-' + cf_name;
        var numi = document.getElementById(adder_el);
        var num = (document.getElementById(adder_el).value -1) + 2;
        numi.value = num;

        // Create the new input field.
        var newInputName = cf_name + '_selectedentriescf_new' + num;
        var new_el = 'se-new-input-' + cf_name;
        var newInput = document.getElementById(new_el).cloneNode(true);
        newInput.setAttribute('name', newInputName);
        newInput.setAttribute('id',   newInputName);

        // Create the new button
        var new_el = 'se-new-button-' + cf_name;
        var newButton = document.getElementById(new_el).cloneNode(true);
        newButton.removeAttribute('id');
        newButton.setAttribute('style', "background: #333 url('<mt:StaticWebPath>images/buttons/button.gif') no-repeat 0 center; border:none; border-top:1px solid #d4d4d4; font-weight: bold; font-size: 14px; line-height: 1.3; text-decoration: none; color: #eee; cursor: pointer; padding: 2px 10px 4px;");
        var onclick = "return openDialog(this.form, 'mcf_list_entries', 'blog_ids=" + blog_ids + "&edit_field=" + newInputName + "')";
        newButton.setAttribute('onclick', onclick);

        // Create the preview area
        var newPreviewName = cf_name + '_selectedentriescf_new' + num + '_preview';
        var new_el = 'se-new-preview-' + cf_name;
        var newPreview = document.getElementById(new_el).cloneNode(true);
        newPreview.setAttribute('id', newPreviewName);
        newPreview.setAttribute('style', 'padding: 0 3px 0 8px;');

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
        var href = "javascript:removeSelectedEntry('li_" + newInputName + "','<mt:Var name="field_name">');";
        newDeleteLink.setAttribute('href', href);
        newDeleteLink.setAttribute('title', 'Remove selected entry');
        newDeleteLink.appendChild(newDeleteIcon);

        // Create a new list item and add the new select drop-down to it.
        var newListItem = document.createElement('li');
        newListItem.setAttribute('id', 'li_' + newInputName);
        newListItem.appendChild(newInput);
        newListItem.appendChild(newButton);
        newListItem.appendChild(newPreview);
        newListItem.appendChild(newDeleteLink);

        // Place the new list item in the drop-down selectors list.
        var CF = document.getElementById('custom-field-selected-entries_' + cf_name);
        CF.appendChild(newListItem);
        
        // If the beacon (added when there are no Selected Assets) is 
        // present, remove it. After all, the user is adding an Asset now,
        // so that state is no longer true.
        var beacon = document.getElementById(cf_name + '_selectedentriescf_beacon');
        if (beacon) {
            CF.removeChild(beacon);
        }

        // After the user clicks to Add an Entry, they are going to want to
        // click Choose Entry. We might as well save them the effort.
        openDialog(this.form, 'mcf_list_entries', 'blog_ids=' + blog_ids + '&edit_field=' + newInputName);
    }
    function removeSelectedEntry(l,f) {
        var listItem = document.getElementById(l);
        listItem.parentNode.removeChild(listItem);
        
        // If the user has just deleted the last Selected Entry, then add a
        // beacon so that the state can be properly saved.
        var ul_field = 'custom-field-selected-entries_' + f;
        var ul = document.getElementById(ul_field);
        var li_count = ul.getElementsByTagName('li').length
        if (li_count == 0) {
            // Create the beacon field.
            var beacon = document.createElement('input');
            beacon_field = f+ '_selectedentriescf_beacon';
            beacon.setAttribute('name', beacon_field);
            beacon.setAttribute('id', beacon_field);
            beacon.setAttribute('type', 'hidden');
            beacon.setAttribute('value', '1');

            // Add the beacon field to the parent UL.
            var CF = document.getElementById(ul_field);
            CF.appendChild(beacon);
        }
    }
</script>
    };
}

sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    my $id       = $app->param('id');
    my $blog     = $app->blog;
    my $blog_id  = $blog ? $blog->id : 0;
    my $obj_type = $tmpl_param->{obj_type};

    my $field_name  = $tmpl_param->{field_name};

    # Several dropdowns may be needed, because several entries were selected.
    my $field_value = $tmpl_param->{field_value};
    
    # If there is no field value, there is nothing to parse. Likely on the
    # Edit Field screen.
    return unless $field_value;
    
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
}

sub tag_selected_entries {
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

    # Use Custom Fields find_stashed_by_type to load the correct object. This
    # will decide if it's an entry, page, category, folder, or author archive,
    # then load the object and return it to us.
    use CustomFields::Template::ContextHandlers;
    my $object = eval {
        CustomFields::Template::ContextHandlers::find_stashed_by_type(
            $ctx, $field->obj_type
        )
    };
    return $ctx->error($@) if $@;

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

sub se_list_entries {
    my $app = shift;
    my $blog_ids = $app->param('blog_ids');
    my $type = 'entry';
    my $pkg = $app->model($type) or return "Invalid request.";

    my %terms = (
         status => '2', 
    );
    
    my @blog_ids;
    if ($blog_ids == 'all') {
        # @blog_ids should stay empty so all blogs are loaded.
    }
    else {
        # Turn this into an array so that all specified blogs can be loaded.
        @blog_ids = split(/,/, $blog_ids);
        $terms{blog_id} = [@blog_ids];
    }
    
    my %args = (
        sort      => 'authored_on',
        direction => 'descend',
    );

    my $plugin = MT->component('MoreCustomFields');
    my $tmpl = $plugin->load_tmpl('entry_list.mtml');
    $tmpl->param('type', $type);

    return $app->listing({
        type => 'entry',
        template => $tmpl,
        params => {
            panel_searchable => 1,
            edit_blog_id     => $blog_ids,
            edit_field       => $app->param('edit_field'),
            search           => $app->param('search'),
            blog_id          => $blog_ids,
        },
        code => sub {
            my ($obj, $row) = @_;
            $row->{'status_' . lc MT::Entry::status_text($obj->status)} = 1;
            $row->{entry_permalink} = $obj->permalink
                if $obj->status == MT::Entry->RELEASE();
            if (my $ts = $obj->authored_on) {
                my $date_format = MT::App::CMS->LISTING_DATE_FORMAT();
                my $datetime_format = MT::App::CMS->LISTING_DATETIME_FORMAT();
                $row->{created_on_formatted} = format_ts($date_format, $ts, $obj->blog,
                    $app->user ? $app->user->preferred_language : undef);
                $row->{created_on_time_formatted} = format_ts($datetime_format, $ts, $obj->blog,
                    $app->user ? $app->user->preferred_language : undef);
                $row->{created_on_relative} = relative_date($ts, time, $obj->blog);
            }
            return $row;
        },
        terms => \%terms,
        args  => \%args,
        limit => 10,
    });
}

sub se_select_entry {
    my $app = shift;

    my $entry_id = $app->param('id')
        or return $app->errtrans('No id');
    my $entry = MT->model('entry')->load($entry_id)
        or return $app->errtrans('No entry #[_1]', $entry_id);
    my $edit_field = $app->param('edit_field')
        or return $app->errtrans('No edit_field');

    my $plugin = MT->component('MoreCustomFields');
    my $tmpl = $plugin->load_tmpl('select_entry.mtml', {
        entry_id    => $entry->id,
        entry_title => $entry->title,
        edit_field  => $edit_field,
    });
    return $tmpl;
}

1;

__END__
