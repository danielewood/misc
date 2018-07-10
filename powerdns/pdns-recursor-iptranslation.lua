--.DESCRIPTION
-- This Lua script for PowerDNS will provide on-the-fly DNS Translation of IPv4 "A" Records.
-- This is to facilitate DNS resolution across a massive 1:1 NAT for network mergers and IP deconfliction.
-- The example configuration below translates 10.54.64.0/18 and 10.54.128.0/18 to 172.19.64.0/18 and 172.19.128.0/18
-- Use this in conjunction with something like the following iptables setup:
        -- https://serverfault.com/questions/109569/iptables-massive-11-nat

--.NOTES
-- License: Unlicense / CCZero / WTFPL / Public Domain
-- Author: Daniel Wood / https://github.com/danielewood
-- References: https://github.com/PowerDNS/pdns/blob/master/pdns/recursordist/contrib/powerdns-example-script.lua


-- User Defined Variables:
local scriptname = 'pdns-recursor-iptranslation.lua'
local networkaddr = '10.54'
local new_networkaddr = '172.19'
-- min/max refers to A.B.C.D, use this to specify a range tighter than /16
-- default values: min/max = 0/255
local c_min = 64
local c_max = 191
local d_min = 0
local d_max = 255


-- Begin Script
pdnslog("pdns-recursor Lua script (" .. scriptname .. ") starting!", pdns.loglevels.Warning)
function postresolve(dq)
        local records = dq:getRecords()
        for k,v in pairs(records) do
                print(k, v.name:toString(), v:getContent())
--              pdnslog(k .. v.name:toString() .. v:getContent())
                if v.type == pdns.A and v:getContent():match(networkaddr .. ".(%d+).(%d+)") then
                        local ipaddr = v:getContent()
                        local a,b,c,d = string.match(ipaddr, "(%d+).(%d+).(%d+).(%d+)")
                        local a = tonumber(a)
                        local b = tonumber(b)
                        local c = tonumber(c)
                        local d = tonumber(d)
                        local new_ipaddr = new_networkaddr .. "." .. c .. "." .. d
                        if c >= c_min and c <= c_max and d >= d_min and d <= d_max then
                                pdnslog(scriptname .. " : IP Translation : (" .. v.name:toString() .. ") " .. ipaddr .. " to " .. new_ipaddr )
                                v:changeContent(new_ipaddr)
                                v.ttl=1
                        end
                end
        end
        dq:setRecords(records)
        return true
end
