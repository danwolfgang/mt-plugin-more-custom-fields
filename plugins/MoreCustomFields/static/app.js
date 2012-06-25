// The popup dialog uses this function to insert the Selected Entry, Selected
// Page, or Reciprocal Association.
function insertSelectedEntry(entry_title, entry_id, field, blog_id) {
    // Check if this is a reciprocal association, or just a standard Selected
    // Entry/Page.
    var type = jQuery('#entry_form input[name=_type]').val();
    if ( jQuery('#'+field+'_reciprocal_'+type).length ) {
        // If a reciprocal association already exists, we need to delete it
        // before creating a new association.
        if ( jQuery('#'+field+'_reciprocal_'+type).val() ) {
            deleteReciprocalAssociation(
                field,
                jQuery('#'+field+'_reciprocal_'+type).val(),
                entry_title,
                entry_id,
                blog_id
            );
        }
        // No existing association exists, so just create the new reciprocal
        // entry association.
        else {
            createReciprocalAssociation(
                entry_title,
                entry_id,
                field,
                blog_id
            );
        }
    }
    // This is just a standard Selected Entries or Selected Pages insert.
    else {
        jQuery('#'+field).val(entry_id);
        jQuery('#'+field+'_preview').text(entry_title);
    }
}

// Create the reciprocal entry association. This happens after selecting
// an entry from the popup.
function createReciprocalAssociation(entrytitle, recip_entry_id, field, blog_id) {
    var type = jQuery('#entry_form input[name=_type]').val();
    jQuery('#'+field+'_reciprocal_'+type).val( recip_entry_id );

    jQuery('#'+field+'_preview').html(
        '<a href="' + CMSScriptURI + '?__mode=view'
        + '&amp;_type=' + type + '&amp;blog_id=' + blog_id + '&amp;id='
        + recip_entry_id + '">' + entrytitle + '</a>'
    );

    jQuery('#'+field+'_delete').show();
}

// Unlink the selected entry from the current entry.
function deleteReciprocalAssociation(field, recip_entry_id, entrytitle, new_recip_entry_id, blog_id) {
    var type = jQuery('#entry_form input[name=_type]').val();
    jQuery.get(
        CMSScriptURI + '?__mode=unlink_reciprocal',
        {
            'recip_field_basename': field,
            'recip_entry_id': recip_entry_id,
            'cur_entry_id': jQuery('input[name=id]').val(),
            'recip_obj_type': type
        },
        function(data) {
            jQuery('#'+field+'_status').html(data.message).show(500);

            // The association was successfully deleted from the database,
            // so delete the visible data.
            if (data.status == 1) {
                jQuery('#'+field+'_reciprocal_'+type).val('');
                jQuery('#'+field+'_preview').html('');
                jQuery('#'+field+'_delete').hide();
                setTimeout(function() {
                    jQuery('#'+field+'_status').hide(1000)
                }, 7000);

                // Is a new entry supposed to be linked now? If so, do it!
                if (entrytitle) {
                    createReciprocalAssociation(
                        entrytitle,
                        new_recip_entry_id,
                        field,
                        blog_id
                    );
                }
            }
        },
        'json'
    );
}

// Selected Entries CF
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
    newButton.setAttribute('style', "background: #333 url('" + StaticURI + "images/buttons/button.gif') no-repeat 0 center; border:none; border-top:1px solid #d4d4d4; font-weight: bold; font-size: 14px; line-height: 1.3; text-decoration: none; color: #eee; cursor: pointer; padding: 2px 10px 4px;");
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
    newDeleteIcon.setAttribute('src', StaticURI + 'images/status_icons/close.gif');
    newDeleteIcon.setAttribute('width', '9');
    newDeleteIcon.setAttribute('height', '9');
    newDeleteIcon.setAttribute('alt', 'Remove selected entry');

    //Add the "delete" link
    var newDeleteLink = document.createElement('a');
    newDeleteLink.setAttribute('style', "margin-left: 5px;");
    newDeleteLink.setAttribute('style', 'padding: 3px 5px;');
    var href = "javascript:removeSelectedEntry('li_" + newInputName + "', '" + cf_name + "');";
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

// Selected Pages CF
function addSelectedPage(cf_name, blog_ids) {
    // Update the counter, so that each addition gets a unique number
    var adder_el = 'se-adder-' + cf_name;
    var numi = document.getElementById(adder_el);
    var num = (document.getElementById(adder_el).value -1) + 2;
    numi.value = num;

    // Create the new input field.
    var newInputName = cf_name + '_selectedpagescf_new' + num;
    var new_el = 'se-new-input-' + cf_name;
    var newInput = document.getElementById(new_el).cloneNode(true);
    newInput.setAttribute('name', newInputName);
    newInput.setAttribute('id',   newInputName);

    // Create the new button
    var new_el = 'se-new-button-' + cf_name;
    var newButton = document.getElementById(new_el).cloneNode(true);
    newButton.removeAttribute('id');
    newButton.setAttribute('style', "background: #333 url('" + StaticURI + "images/buttons/button.gif') no-repeat 0 center; border:none; border-top:1px solid #d4d4d4; font-weight: bold; font-size: 14px; line-height: 1.3; text-decoration: none; color: #eee; cursor: pointer; padding: 2px 10px 4px;");
    var onclick = "return openDialog(this.form, 'mcf_list_pages', 'blog_ids=" + blog_ids + "&edit_field=" + newInputName + "')";
    newButton.setAttribute('onclick', onclick);

    // Create the preview area
    var newPreviewName = cf_name + '_selectedpagescf_new' + num + '_preview';
    var new_el = 'se-new-preview-' + cf_name;
    var newPreview = document.getElementById(new_el).cloneNode(true);
    newPreview.setAttribute('id', newPreviewName);
    newPreview.setAttribute('style', 'padding: 0 3px 0 8px;');

    // Add the "delete" icon
    var newDeleteIcon = document.createElement('img');
    newDeleteIcon.setAttribute('src', StaticURI + 'images/status_icons/close.gif');
    newDeleteIcon.setAttribute('width', '9');
    newDeleteIcon.setAttribute('height', '9');
    newDeleteIcon.setAttribute('alt', 'Remove selected page');

    //Add the "delete" link
    var newDeleteLink = document.createElement('a');
    newDeleteLink.setAttribute('style', "margin-left: 5px;");
    newDeleteLink.setAttribute('style', 'padding: 3px 5px;');
    var href = "javascript:removeSelectedPage('li_" + newInputName + "','" + cf_name + "');";
    newDeleteLink.setAttribute('href', href);
    newDeleteLink.setAttribute('title', 'Remove selected page');
    newDeleteLink.appendChild(newDeleteIcon);

    // Create a new list item and add the new select drop-down to it.
    var newListItem = document.createElement('li');
    newListItem.setAttribute('id', 'li_' + newInputName);
    newListItem.appendChild(newInput);
    newListItem.appendChild(newButton);
    newListItem.appendChild(newPreview);
    newListItem.appendChild(newDeleteLink);

    // Place the new list item in the drop-down selectors list.
    var CF = document.getElementById('custom-field-selected-pages_' + cf_name);
    CF.appendChild(newListItem);
    
    // If the beacon (added when there are no Selected Pages) is 
    // present, remove it. After all, the user is adding an Entry now,
    // so that state is no longer true.
    var beacon = document.getElementById(cf_name + '_selectedpagescf_beacon');
    if (beacon) {
        CF.removeChild(beacon);
    }

    // After the user clicks to Add a Page, they are going to want to
    // click Choose Page. We might as well save them the effort.
    openDialog(this.form, 'mcf_list_pages', 'blog_ids=' + blog_ids + '&edit_field=' + newInputName);
}

function removeSelectedPage(l,f) {
    var listItem = document.getElementById(l);
    listItem.parentNode.removeChild(listItem);

    // If the user has just deleted the last Selected Entry, then add a
    // beacon so that the state can be properly saved.
    var ul_field = 'custom-field-selected-pages_' + f;
    var ul = document.getElementById(ul_field);
    var li_count = ul.getElementsByTagName('li').length
    if (li_count == 0) {
        // Create the beacon field.
        var beacon = document.createElement('input');
        beacon_field = f+ '_selectedpagescf_beacon';
        beacon.setAttribute('name', beacon_field);
        beacon.setAttribute('id', beacon_field);
        beacon.setAttribute('type', 'hidden');
        beacon.setAttribute('value', '1');

        // Add the beacon field to the parent UL.
        var CF = document.getElementById(ul_field);
        CF.appendChild(beacon);
    }
}
