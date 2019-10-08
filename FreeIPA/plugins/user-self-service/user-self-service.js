/* Author: 
 *   Daniel Wood / https://github.com/danielewood
 * 
 * Modified from:
 *    Original js: https://pvoborni.fedorapeople.org/plugins/simpleuser/simpleuser.js
 *    Full User attritbues js source: https://github.com/freeipa/freeipa/blob/master/install/ui/src/freeipa/user.js
 */

/*  Authors:
 *    Petr Vobornik <pvoborni@redhat.com>
 *
 * Copyright (C) 2013 Red Hat
 * see file 'COPYING' for use and warranty information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// we can also depend on other plugin
define(['freeipa/ipa',
        'freeipa/menu',
        'freeipa/phases',
        'freeipa/reg'
        ],
            function(IPA, menu, phases, reg) {


var exp = {}; // module object (export)

// new self-service page

var make_spec = function() {
return {
    name: 'user',
    enable_test: function() {
        // enabled only if not self-service
        return IPA.is_selfservice;
    },
    facets: [
        {
            $type: 'details',
            disable_breadcrumb: true,
            sections: [
                {
                    name: 'identity',
                    label: '@i18n:details.identity',
                    fields: [
                        'title',
                        'givenname',
                        'sn',
                        'cn',
                        'displayname',
                        'initials',
                        'gecos',
                        { $type: 'multivalued', name: 'mail' },
                        'street',
                        'l',
                        'st',
                        'postalcode',
                        { $type: 'multivalued', name: 'telephonenumber' },
                        { $type: 'multivalued', name: 'mobile' }
                    ]
                },
                {
                    name: 'account',
                    fields: [
                        'uid',
                        {
                            $type: 'datetime',
                            name: 'krbpasswordexpiration',
                            label: '@i18n:objects.user.krbpasswordexpiration',
                            read_only: true
                        },
                        'uidnumber',
                        'gidnumber',
                        'krbprincipalname',
                        'krbprincipalexpiration',
                        {
                            $type: 'datetime',
                            name: 'krbprincipalexpiration'
                        },
                        'loginshell',
                        'homedirectory',
                        {
                            $type: 'sshkeys',
                            name: 'ipasshpubkey',
                            label: '@i18n:objects.sshkeystore.keys'
                        }
                    ]
                }
            ]
        }
    ]
};};

exp.entity_spec = make_spec();
exp.override = function() {
    if (!IPA.is_selfservice) return;
    var e = reg.entity;
    e.register({type: 'user', spec: exp.entity_spec});

    //delete original - was created upon menu creation
    e.set('user', null);

    // remove menu items we dont want the user to see
    menu.remove_item('otptoken');
    menu.remove_item('user');

};

// need to do it in profile phase - because of IPA.is_selfservice
phases.on('profile', exp.override, 20);

return exp;
});
