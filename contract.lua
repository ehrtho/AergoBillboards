-- AERGO BILLBOARDS
-- UNDER DEVELOPMENT

-- GLOBAL STATE VARIABLES
state.var {
  
  __GEO = state.map(2), -- Geographic Coordinate System for outdoors map
  __OUTDOORS = state.map(1) -- outdoors collectable data
  --_b_aer_coupon = state.value() -- bignum aer of 1 collectable ticket

}

function constructor()  
  
  __OUTDOORS["counter"] = 0
  
  --_b_aer_coupon:set (bignum.tonumber("10000000")) -- ?
  
end



---------------------------------------------------------------------
-------- < PRIVATE FUNCTIONS >
---------------------------------------------------------------------


---------------------------------------
-- Checks and converts GCS to valid latitude and longitude
-- @type    function
-- @param   gcs     Geographic coordinate system
-- @return  latitude, longitude strings (25.6466799,-47.5589549 --> -25.64   -47.55)
---------------------------------------
function gcs2latlong(gcs)  
  
  local pattern = "^%s*(%-?%d?%d%.%d%d)%d*%s*.%s*(%-?1?%d?%d%.%d%d)%d*%s*$"
  
  assert(type(gcs)=="string" and gcs:find(pattern), "[gcs] invalid parameter")  
  
  local lat, long = gcs:match(pattern)
  
  -- removes extras zeros, but NOT in decimal places
  lat, long = tonumber(lat.."5"), tonumber(long.."5")
  
  assert((lat >= -90 and lat <= 90) and (long >= -180 and long <= 180), "[gcs] invalid GCS")
  
  return tostring(lat):sub(1, -2), tostring(long):sub(1, -2) -- removes the "5" in the end

end


---------------------------------------
-- Check address correctness
-- @type function
-- @param   address address to check
-- @return  boolean valid or not
---------------------------------------
function isValidAddress(address)
  -- check existence of invalid alphabets
  if nil ~= string.match(address, '[^123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]') then
    return false
  end

  -- check length is in range
  if 52 ~= string.len(address) then
    return false
  end

  return true
end


---------------------------------------
-- Collect one coupon from outdoor (if avaliable)
-- @type query
-- @param   address   address to send the coupon prize
-- @return  nounce    outdoor id
---------------------------------------
function collect(address, nounce)
  
  if type(__OUTDOORS[nounce]) == "table" then -- exists?
    
    local outdoor = __OUTDOORS[nounce]
    
    -- verifica se está no tempo ainda
    -- verifica se possui total
    -- verifica se secret está correta
    
    -- trasnfere
    
    --outdoor
    
    
  end
  
end


---------------------------------------------------------------------
-------- </ PRIVATE FUNCTIONS >
---------------------------------------------------------------------






---------------------------------------------------------------------
-------- < VIEW FUNCTIONS >
---------------------------------------------------------------------

---------------------------------------
-- Gets all outdoors from region gcs
-- @type    view
-- @param   gcs     Geographic coordinate system
---------------------------------------
function view_region(gcs)   
    
    local lat, long = gcs2latlong(gcs)
 
    return json.encode(__GEO[lat][long] or {})    
    
end



---------------------------------------------------------------------
-------- </ VIEW FUNCTIONS >
---------------------------------------------------------------------



---------------------------------------------------------------------
-------- < PAYABLE FUNCTIONS >
---------------------------------------------------------------------



---------------------------------------
-- Buy a new outdoor
-- @type    payable
-- @param   gcs      Geographic Coordinate System
-- @param   payload  payload of social network post (NOTICE: first char MUST BE the type (IG = 1, FB = 2, YT = 3...))
-- @param   coupon   3 to 6 uppercase letters not-encrypted
-- @param   total    how much collectable coupons are able to collect in units
-- @param   refer    valid aergo address to receive 1 free coupon
function payable_outdoor(gcs, payload, coupon, total, refer)       
    
    local lat, long = gcs2latlong(gcs)
    
    local bignum_aer_amount = bignum.number(system.getAmount())
    local sender = system.getSender()

    assert(type(coupon)=="string" and coupon:find("^%u%u%u%u?%u?%u?$"), "[coupon] invalid parameter")    
    
    -- total it's a number?
    total = tostring(total)
    assert(total:find("^[0-9]+$") and #total <= 4 , "[total] invalid parameter") -- maximum total is 9999 collectables    
    -- total minimum amount    
    total = tonumber(total)    
    assert(total >= 100, "[total] insufficient parameter (minimum is 100)")    
    local bignum_div = bignum.div(bignum_aer_amount, bignum.number(total))
    -- total minimum collectable    
    assert(bignum.compare(bignum_div, bignum.number("5000000000000000")) > -1, "[total] unfair collectables division ")
    
    __OUTDOORS["counter"] = __OUTDOORS["counter"] + 1    
    local nounce = tostring(__OUTDOORS["counter"])
    
    local now = system.getTimestamp()
    
    __OUTDOORS[nounce] = {
      now,                                    -- check time if is valid
      bignum_div,                             -- prize
      total,                                  -- avaliable
      crypto.sha256(coupon)                   -- secret
    }
   
    local outdoor = {
      nounce,                                 -- id
      gcs,                                    -- location
      payload,                                -- post
      tostring(bignum_aer_amount),            -- z-order
      now                                     -- creation time
    }
   
    if type(__GEO[lat][long]) == "table" then
      table.insert(__GEO[lat][long], outdoor)    
    else
      __GEO[lat][long] = {outdoor}
    end
    
    if isValidAddress(tostring(refer)) then
      collect(refer, nounce)
    end
    
end

---------------------------------------------------------------------
-------- </ PAYABLE FUNCTIONS >
---------------------------------------------------------------------

abi.register_view(view_region)
abi.payable(new_outdoor)