-- [VERSION 1.21]
-- Made by GplateGam

local CFrame = {}
CFrame.Version = "V1.21"

local pi = math.pi
local epsilon = 1e-6

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

local function newCFrame(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
	local self = setmetatable({}, CFrame)
	self.x = x or 0
	self.y = y or 0
	self.z = z or 0
	self.r00 = r00 or 1
	self.r01 = r01 or 0
	self.r02 = r02 or 0
	self.r10 = r10 or 0
	self.r11 = r11 or 1
	self.r12 = r12 or 0
	self.r20 = r20 or 0
	self.r21 = r21 or 0
	self.r22 = r22 or 1

	return self
end

CFrame.identity = newCFrame(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
CFrame.Identity = newCFrame(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

local function quaternionToMatrix(qx, qy, qz, qw)
	local x2, y2, z2 = qx + qx, qy + qy, qz + qz
	local xx, yy, zz = qx*x2, qy*y2, qz*z2
	local xy, xz, yz = qx*y2, qx*z2, qy*z2
	local wx, wy, wz = qw*x2, qw*y2, qw*z2

	return 1 - (yy + zz), xy - wz, xz + wy, xy + wz, 1 - (xx + zz), yz - wx, xz - wy, yz + wx, 1 - (xx + yy)
end

local function matrixToQuaternion(r00, r01, r02, r10, r11, r12, r20, r21, r22)
	local trace = r00 + r11 + r22
	local qx, qy, qz, qw

	if trace > 0 then
		local s = math.sqrt(trace + 1)*2
		qw = 0.25*s
		qx = (r21 - r12)/s
		qy = (r02 - r20)/s
		qz = (r10 - r01)/s
	elseif r00 > r11 and r00 > r22 then
		local s = math.sqrt(1 + r00 - r11 - r22)*2
		qw = (r21 - r12)/s
		qx = 0.25*s
		qy = (r01 + r10)/s
		qz = (r02 + r20)/s
	elseif r11 > r22 then
		local s = math.sqrt(1 + r11 - r00 - r22)*2
		qw = (r02 - r20)/s
		qx = (r01 + r10)/s
		qy = 0.25*s
		qz = (r12 + r21)/s
	else
		local s = math.sqrt(1 + r22 - r00 - r11)*2
		qw = (r10 - r01)/s
		qx = (r02 + r20)/s
		qy = (r12 + r21)/s
		qz = 0.25*s
	end

	return qx, qy, qz, qw
end

local function orthonormalize(vx, vy, vz)
    vx = Vector3.Normalize(vx)

    local dot = Vector3.Dot(vx, vy)
    vy = Vector3.New(vy.x - dot*vx.x, vy.y - dot*vx.y, vy.z - dot*vx.z)

    if vy.sqrMagnitude < epsilon then
        local alt = (math.abs(vx.x) < 0.9) and Vector3.New(1, 0, 0) or Vector3.New(0, 1, 0)
        vy = Vector3.Normalize(Vector3.Cross(vx, alt))
    else
        vy = Vector3.Normalize(vy)
    end

    vz = Vector3.Cross(vx, vy)
    return vx, vy, vz
end

function CFrame.New(...)
	local args = {...}
	local n = #args
	if n == 0 then
		return newCFrame(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	elseif n == 1 then
		local pos = args[1]
		return newCFrame(pos.x, pos.y, pos.z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	elseif n == 2 then
		local pos = args[1]
		local lookAt = args[2]
		local forward = Vector3.New(lookAt.x - pos.x, lookAt.y - pos.y, lookAt.z - pos.z)

		if forward.sqrMagnitude < epsilon*epsilon then
			return newCFrame(pos.x, pos.y, pos.z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
		end

		forward = Vector3.Normalize(forward)

		local right = nil
		local upDot = math.abs(forward.y)

		if upDot < 0.99 then
			right = Vector3.New(-forward.z, 0, forward.x)
		else
			right = Vector3.New(1, 0, 0)
		end

		right = Vector3.Normalize(right)
		local up = Vector3.Cross(right, forward)

		return newCFrame(
            pos.x, pos.y, pos.z,
            right.x, up.x, -forward.x,
            right.y, up.y, -forward.y,
            right.z, up.z, -forward.z
        )
	elseif n == 3 then
		return newCFrame(args[1], args[2], args[3], 1, 0, 0, 0, 1, 0, 0, 0, 1)
	elseif n == 7 then
		local x, y, z, qx, qy, qz, qw = table.unpack(args)
		local r00, r01, r02, r10, r11, r12, r20, r21, r22 = quaternionToMatrix(qx, qy, qz, qw)

		return newCFrame(
            x, y, z,
            r00, r01, r02,
            r10, r11, r12,
            r20, r21, r22
        )
	elseif n == 12 then
        return newCFrame(table.unpack(args))
    end
	error("Invalid number of arguments to CFrame.New/CFrame.new")
end

function CFrame.new(...)
	return CFrame.New(...)
end

function CFrame.lookAt(at, lookAt, up)
	up = up or Vector3.New(0, 1, 0)

	local back = Vector3.New(at.x - lookAt.x, at.y - lookAt.y, at.z - lookAt.z)
	if back.sqrMagnitude < epsilon*epsilon then
		return newCFrame(at.x, at.y, at.z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	end
	back = Vector3.Normalize(back)

	local right = Vector3.Cross(up, back)
	if right.sqrMagnitude < epsilon*epsilon then
		return newCFrame(at.x, at.y, at.z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	end
	right = Vector3.Normalize(right)

	local newUp = Vector3.Cross(back, right)
	return newCFrame(
        at.x, at.y, at.z,
        right.x, newUp.x, back.x,
        right.y, newUp.y, back.y,
        right.z, newUp.z, back.z
    )
end

function CFrame.lookAlong(at, direction, up)
	up = up or Vector3.New(0, 1, 0)

	if direction.sqrMagnitude < epsilon*epsilon then
		return newCFrame(at.x, at.y, at.z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	end

	local back = Vector3.New(-direction.x, -direction.y, -direction.z)
	back = Vector3.Normalize(back)

	local right = Vector3.Cross(up, back)
	if right.sqrMagnitude < epsilon*epsilon then
		return newCFrame(at.x, at.y, at.z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	end
	right = Vector3.Normalize(right)

	local newUp = Vector3.Cross(back, right)
	return newCFrame(
        at.x, at.y, at.z,
        right.x, newUp.x, back.x,
        right.y, newUp.y, back.y,
        right.z, newUp.z, back.z
    )
end

function CFrame.fromRotationBetweenVectors(from, to)
	if from.sqrMagnitude < epsilon*epsilon or to.sqrMagnitude < epsilon*epsilon then
		return newCFrame(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	end

	from = Vector3.Normalize(from)
	to = Vector3.Normalize(to)

	local dot = Vector3.Dot(from, to)

	if dot > 0.99999 then
		return newCFrame(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	elseif dot < -0.99999 then
		local axis
		if math.abs(from.x) < 0.9 then
			axis = Vector3.New(1, 0, 0)
		else
			axis = Vector3.New(0, 1, 0)
		end

		axis = Vector3.Normalize(Vector3.Cross(from, axis))
		return CFrame.fromAxisAngle(axis, pi)
	end

	local axis = Vector3.Cross(from, to)
	local qw = 1 + dot
	local qx, qy, qz = axis.x, axis.y, axis.z

	local mag = math.sqrt(qx*qx + qy*qy + qz*qz + qw*qw)
	qx, qy, qz, qw = qx/mag, qy/mag, qz/mag, qw/mag
	local r00, r01, r02, r10, r11, r12, r20, r21, r22 = quaternionToMatrix(qx, qy, qz, qw)

	return newCFrame(0, 0, 0, r00, r01, r02, r10, r11, r12, r20, r21, r22)
end

function CFrame.fromEulerAngles(rx, ry, rz, order)
	order = order or 5

	local cx, sx = math.cos(rx), math.sin(rx)
	local cy, sy = math.cos(ry), math.sin(ry)
	local cz, sz = math.cos(rz), math.sin(rz)
	local r00, r01, r02, r10, r11, r12, r20, r21, r22

	if order == 0 then
		r00 = cy*cz
		r01 = -cy*sz
		r02 = sy
		r10 = sx*sy*cz + cx*sz
		r11 = -sx*sy*sz + cx*cz
		r12 = -sx*cy
		r20 = -cx*sy*cz + sx*sz
		r21 = cx*sy*sz + sx*cz
		r22 = cx*cy
	elseif order == 1 then
		r00 = cy*cz
		r01 = -sz
		r02 = sy*cz
		r10 = cy*sz*cx + sy*sx
		r11 = cz*cx
		r12 = sy*sz*cx - cy*sx
		r20 = cy*sz*sx - sy*cx
		r21 = cz*sx
		r22 = sy*sz*sx + cy*cx
	elseif order == 2 then
		r00 = cy*cz + sy*sx*sz
		r01 = -cy*sz + sy*sx*cz
		r02 = sy*cx
		r10 = cx*sz
		r11 = cx*cz
		r12 = -sx
		r20 = -sy*cz + cy*sx*sz
		r21 = sy*sz + cy*sx*cz
		r22 = cy*cx
	elseif order == 3 then
		r00 = cy*cz
		r01 = sy*sx - cy*sz*cx
		r02 = sy*cx + cy*sz*sx
		r10 = sz
		r11 = cz*cx
		r12 = -cz*sx
		r20 = -sy*cz
		r21 = cy*sx + sy*sz*cx
		r22 = cy*cx - sy*sz*sx
	elseif order == 4 then
		r00 = cy*cz - sy*sx*sz
		r01 = -cx*sz
		r02 = sy*cz + cy*sx*sz
		r10 = cy*sz + sy*sx*cz
		r11 = cx*cz
		r12 = sy*sz - cy*sx*cz
		r20 = -sy*cx
		r21 = sx
		r22 = cy*cx
	else
		r00 = cy*cz
		r01 = cz*sy*sx - sz*cx
		r02 = cz*sy*cx + sz*sx
		r10 = cy*sz
		r11 = sz*sy*sx + cz*cx
		r12 = sz*sy*cx - cz*sx
		r20 = -sy
		r21 = cy*sx
		r22 = cy*cx
	end

	return newCFrame(0, 0, 0, r00, r01, r02, r10, r11, r12, r20, r21, r22)
end

function CFrame.fromPolyRotation(PolyRotation)
	local rx = math.rad(PolyRotation.x % 360)
	local ry = math.rad(PolyRotation.y % 360)
	local rz = math.rad(PolyRotation.z % 360)

	return CFrame.fromEulerAnglesYXZ(rx, ry, rz)
end

function CFrame.fromEulerAnglesXYZ(rx, ry, rz)
	return CFrame.fromEulerAngles(rx, ry, rz, 0)
end

function CFrame.fromEulerAnglesYXZ(rx, ry, rz)
    return CFrame.fromEulerAngles(rx, ry, rz, 2)
end

function CFrame.Angles(rx, ry, rz)
    return CFrame.fromEulerAnglesYXZ(rx, ry, rz)
end

function CFrame.fromOrientation(rx, ry, rz)
	return CFrame.fromEulerAnglesYXZ(rx, ry, rz)
end

function CFrame.fromAxisAngle(v, r)
	if v.sqrMagnitude < epsilon*epsilon then
		return newCFrame(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	end

	local axis = Vector3.Normalize(v)
	local halfAngle = r*0.5
	local s = math.sin(halfAngle)
	local c = math.cos(halfAngle)

	local qx = axis.x*s
	local qy = axis.y*s
	local qz = axis.z*s
	local qw = c

	local r00, r01, r02, r10, r11, r12, r20, r21, r22 = quaternionToMatrix(qx, qy, qz, qw)
	return newCFrame(0, 0, 0, r00, r01, r02, r10, r11, r12, r20, r21, r22)
end

function CFrame.fromMatrix(pos, vX, vY, vZ)
    if not vZ then
        vZ = Vector3.Cross(vX, vY)
    end

    vX, vY, vZ = orthonormalize(vX, vY, vZ)
    return newCFrame(
    pos.x, pos.y, pos.z,
    vX.x, vY.x, vZ.x,
    vX.y, vY.y, vZ.y,
    vX.z, vY.z, vZ.z
)
end

function CFrame:__mul(other)
    local ot = type(other)
	if ot ~= "table" and ot ~= "userdata" then
		error("CFrame: attempt to multiply with incompatible type '" .. ot .. "'", 2)
	end

	if other.r00 ~= nil then
		local x = self.r00*other.x + self.r01*other.y + self.r02*other.z + self.x
		local y = self.r10*other.x + self.r11*other.y + self.r12*other.z + self.y
		local z = self.r20*other.x + self.r21*other.y + self.r22*other.z + self.z
		local r00 = self.r00*other.r00 + self.r01*other.r10 + self.r02*other.r20
		local r01 = self.r00*other.r01 + self.r01*other.r11 + self.r02*other.r21
		local r02 = self.r00*other.r02 + self.r01*other.r12 + self.r02*other.r22
		local r10 = self.r10*other.r00 + self.r11*other.r10 + self.r12*other.r20
		local r11 = self.r10*other.r01 + self.r11*other.r11 + self.r12*other.r21
		local r12 = self.r10*other.r02 + self.r11*other.r12 + self.r12*other.r22
		local r20 = self.r20*other.r00 + self.r21*other.r10 + self.r22*other.r20
		local r21 = self.r20*other.r01 + self.r21*other.r11 + self.r22*other.r21
		local r22 = self.r20*other.r02 + self.r21*other.r12 + self.r22*other.r22

		return newCFrame(
            x, y, z,
            r00, r01, r02,
            r10, r11, r12,
            r20, r21, r22
        )
    elseif other.x ~= nil and other.y ~= nil and other.z ~= nil then
		local x = self.r00*other.x + self.r01*other.y + self.r02*other.z + self.x
		local y = self.r10*other.x + self.r11*other.y + self.r12*other.z + self.y
		local z = self.r20*other.x + self.r21*other.y + self.r22*other.z + self.z

		return Vector3.New(x, y, z)
	else
		local x = self.r00*other.x + self.r01*other.y + self.r02*other.z + self.x
		local y = self.r10*other.x + self.r11*other.y + self.r12*other.z + self.y
		local z = self.r20*other.x + self.r21*other.y + self.r22*other.z + self.z

		return Vector3.New(x, y, z)
	end
end

function CFrame:__add(other)
	local ot = type(other)
	if (ot ~= "table" and ot ~= "userdata") or other.x == nil then
		error("CFrame: __add requires a value with .x/.y/.z fields", 2)
	end

	return newCFrame(
		self.x + other.x, self.y + other.y, self.z + other.z,
		self.r00, self.r01, self.r02,
		self.r10, self.r11, self.r12,
		self.r20, self.r21, self.r22
	)
end
 
function CFrame:__sub(other)
	local ot = type(other)
	if (ot ~= "table" and ot ~= "userdata") or other.x == nil then
		error("CFrame: __sub requires a value with .x/.y/.z fields", 2)
	end
    
	return newCFrame(
		self.x - other.x, self.y - other.y, self.z - other.z,
		self.r00, self.r01, self.r02,
		self.r10, self.r11, self.r12,
		self.r20, self.r21, self.r22
	)
end

function CFrame:Inverse()
	local x = -(self.r00*self.x + self.r10*self.y + self.r20*self.z)
	local y = -(self.r01*self.x + self.r11*self.y + self.r21*self.z)
	local z = -(self.r02*self.x + self.r12*self.y + self.r22*self.z)

	return newCFrame(
        x, y, z,
        self.r00, self.r10, self.r20,
        self.r01, self.r11, self.r21,
        self.r02, self.r12, self.r22
    )
end

function CFrame:Lerp(goal, alpha)
	if alpha <= 0 then return newCFrame(self:GetComponents()) end
	if alpha >= 1 then return newCFrame(goal:GetComponents()) end

	alpha = clamp(alpha, 0, 1)

	local pos = Vector3.Lerp(
		Vector3.New(self.x, self.y, self.z),
		Vector3.New(goal.x, goal.y, goal.z),
		alpha
	)

	local qx1, qy1, qz1, qw1 = matrixToQuaternion(self.r00, self.r01, self.r02, self.r10, self.r11, self.r12, self.r20, self.r21, self.r22)
	local qx2, qy2, qz2, qw2 = matrixToQuaternion(goal.r00, goal.r01, goal.r02, goal.r10, goal.r11, goal.r12, goal.r20, goal.r21, goal.r22)
	local dot = qx1*qx2 + qy1*qy2 + qz1*qz2 + qw1*qw2

	if dot < 0 then
		qx2, qy2, qz2, qw2 = -qx2, -qy2, -qz2, -qw2
		dot = -dot
	end

	local qx, qy, qz, qw

	if dot > 0.9995 then
		qx = qx1 + (qx2 - qx1)*alpha
		qy = qy1 + (qy2 - qy1)*alpha
		qz = qz1 + (qz2 - qz1)*alpha
		qw = qw1 + (qw2 - qw1)*alpha
	else
		local theta = math.acos(dot)
		local sinTheta = math.sin(theta)
		local w1 = math.sin((1 - alpha)*theta)/sinTheta
		local w2 = math.sin(alpha*theta)/sinTheta
		qx = qx1*w1 + qx2*w2
		qy = qy1*w1 + qy2*w2
		qz = qz1*w1 + qz2*w2
		qw = qw1*w1 + qw2*w2
	end

	local mag = math.sqrt(qx*qx + qy*qy + qz*qz + qw*qw)
	qx, qy, qz, qw = qx/mag, qy/mag, qz/mag, qw/mag

	local r00, r01, r02, r10, r11, r12, r20, r21, r22 = quaternionToMatrix(qx, qy, qz, qw)
	return newCFrame(
        pos.x, pos.y, pos.z,
        r00, r01, r02,
        r10, r11, r12,
        r20, r21, r22
    )
end

function CFrame:ToWorldSpace(cf)
	return self*cf
end

function CFrame:ToObjectSpace(cf)
	return self:Inverse()*cf
end

function CFrame:PointToWorldSpace(v)
	return self*v
end

function CFrame:PointToObjectSpace(v)
	local rel = Vector3.New(v.x - self.x, v.y - self.y, v.z - self.z)
	return Vector3.New(
        self.r00*rel.x + self.r10*rel.y + self.r20*rel.z,
        self.r01*rel.x + self.r11*rel.y + self.r21*rel.z,
        self.r02*rel.x + self.r12*rel.y + self.r22*rel.z
    )
end

function CFrame:VectorToWorldSpace(v)
	return Vector3.New(
        self.r00*v.x + self.r01*v.y + self.r02*v.z,
        self.r10*v.x + self.r11*v.y + self.r12*v.z,
        self.r20*v.x + self.r21*v.y + self.r22*v.z
    )
end

function CFrame:VectorToObjectSpace(v)
	return Vector3.New(
        self.r00*v.x + self.r10*v.y + self.r20*v.z,
        self.r01*v.x + self.r11*v.y + self.r21*v.z,
        self.r02*v.x + self.r12*v.y + self.r22*v.z
    )
end

function CFrame:GetComponents()
	return self.x, self.y, self.z, self.r00, self.r01, self.r02, self.r10, self.r11, self.r12, self.r20, self.r21,self.r22
end

function CFrame:ToEulerAnglesXYZ()
	local x, y, z
	local sy = self.r02

	if math.abs(sy - 1) < epsilon then
		y = pi*0.5
		x = math.atan2(self.r10, self.r11)
		z = 0
	elseif math.abs(sy + 1) < epsilon then
		y = -pi*0.5
		x = -math.atan2(self.r10, self.r11)
		z = 0
	else
		y = math.asin(clamp(sy, -1, 1))
		x = math.atan2(-self.r12, self.r22)
		z = math.atan2(-self.r01, self.r00)
	end

	return x, y, z
end

function CFrame:ToEulerAnglesYXZ()
	local x, y, z
	local sx = -self.r12

	if math.abs(sx - 1) < epsilon then
		x = pi*0.5
		y = math.atan2(-self.r01, self.r00)
		z = 0
	elseif math.abs(sx + 1) < epsilon then
		x = -pi*0.5
		y = -math.atan2(-self.r01, self.r00)
		z = 0
	else
		x = math.asin(clamp(sx, -1, 1))
		y = math.atan2(self.r02, self.r22)
		z = math.atan2(self.r10, self.r11)
	end

	return x, y, z
end

function CFrame:ToOrientation()
	return self:ToEulerAnglesYXZ()
end

function CFrame:ToAxisAngle()
	local qx, qy, qz, qw = matrixToQuaternion(
		self.r00,self.r01,self.r02,
		self.r10,self.r11,self.r12,
		self.r20,self.r21,self.r22
	)

	local angle = 2*math.acos(clamp(qw, -1, 1))
	local s = math.sqrt(1 - qw*qw)
 
	if s < 0.001 then
		return Vector3.New(1, 0, 0), 0
	else
		return Vector3.New(qx/s, qy/s, qz/s), angle
	end
end

function CFrame:ToRotationVector()
	local angle = math.acos(clamp((self.r00 + self.r11 + self.r22 - 1)*0.5, -1, 1))
	if angle < epsilon then return Vector3.New(0, 0, 0) end

    if math.abs(angle - pi) < 1e-4 then
		local ax = math.sqrt(math.max(0, (self.r00 + 1)*0.5))
		local ay = math.sqrt(math.max(0, (self.r11 + 1)*0.5))
		local az = math.sqrt(math.max(0, (self.r22 + 1)*0.5))
		if self.r10 < 0 then ay = -ay end
		if self.r20 < 0 then az = -az end
		return Vector3.New(ax*angle, ay*angle, az*angle)
	end

	local denom = 2*math.sin(angle)
	local x = (self.r21 - self.r12)/denom
	local y = (self.r02 - self.r20)/denom
	local z = (self.r10 - self.r01)/denom

	return Vector3.New(x*angle, y*angle, z*angle)
end

function CFrame:Orthonormalize()
	local vx = Vector3.New(self.r00, self.r10, self.r20)
	local vy = Vector3.New(self.r01, self.r11, self.r21)
	local vz = Vector3.New(self.r02, self.r12, self.r22)

	vx, vy, vz = orthonormalize(vx, vy, vz)

	return newCFrame(
        self.x, self.y, self.z,
        vx.x, vy.x, vz.x,
        vx.y, vy.y, vz.y,
        vx.z, vy.z, vz.z
    )
end

function CFrame:ToPolyRotation()
	local x, y, z = self:ToEulerAnglesYXZ()
	return Vector3.New(math.deg(x), math.deg(y), math.deg(z))
end

CFrame.__index = function(self, key)
    if type(key) ~= "string" then return CFrame[key] end
    local lowercasekey = key:lower()

	if lowercasekey == "position" or lowercasekey == "pos" or lowercasekey == "p" then
		return Vector3.New(self.x, self.y, self.z)
	elseif lowercasekey == "x" then
		return self.x
	elseif lowercasekey == "y" then
		return self.y
	elseif lowercasekey == "z" then
		return self.z
	elseif key == "LookVector" then
		return Vector3.New(-self.r02, -self.r12, -self.r22)
	elseif key == "RightVector" then
		return Vector3.New(self.r00, self.r10, self.r20)
	elseif key == "UpVector" then
		return Vector3.New(self.r01, self.r11, self.r21)
	elseif key == "XVector" then
		return Vector3.New(self.r00, self.r10, self.r20)
	elseif key == "YVector" then
		return Vector3.New(self.r01, self.r11, self.r21)
	elseif key == "ZVector" then
		return Vector3.New(self.r02, self.r12, self.r22)
	else
		return CFrame[key]
	end
end

function CFrame.MoveCFrame(instance, cframe)
	if not instance then
		return
	end

	local pos = Vector3.New(cframe.x, cframe.y, cframe.z)
	local rot = cframe:ToPolyRotation()

	instance:MovePosition(pos)
	instance:MoveRotation(rot)
end

function CFrame.GetCFrame(instance)
	if not instance then
		return CFrame.new()
	end

	local pos = instance.Position or Vector3.New(0, 0, 0)
	local rot = instance.Rotation or Vector3.New(0, 0, 0)

	local rotCF = CFrame.fromEulerAnglesYXZ(math.rad(rot.x % 360), math.rad(rot.y % 360), math.rad(rot.z % 360))
	return newCFrame(
        pos.x, pos.y, pos.z,
        rotCF.r00, rotCF.r01, rotCF.r02,
        rotCF.r10, rotCF.r11, rotCF.r12,
        rotCF.r20, rotCF.r21, rotCF.r22
    )
end

function CFrame.SetCFrame(instance, cframe)
	if not instance then
		return
	end

	local pos = Vector3.New(cframe.x, cframe.y, cframe.z)
	local rot = cframe:ToPolyRotation()

	instance.Position = pos
	instance.Rotation = rot
end

function CFrame.SetLocalCFrame(instance, cframe)
	if not instance then
		return
	end

	local pos = Vector3.New(cframe.x, cframe.y, cframe.z)
	local rot = cframe:ToPolyRotation()

	instance.LocalPosition = pos
	instance.LocalRotation = rot
end

function CFrame.TweenCFrame(instance, cframe, duration, tweentype, callback)
	if not instance then
		return
	end

	local pos = Vector3.New(cframe.x, cframe.y, cframe.z)
	local rot = cframe:ToPolyRotation()

	local tweenPosId = Tween:TweenPosition(instance, pos, duration, tweentype, callback)
	local tweenRotId = Tween:TweenRotation(instance, rot, duration, tweentype)

	return tweenPosId, tweenRotId
end

return CFrame
