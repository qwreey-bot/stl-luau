local treeset = {}

function treeset.from_function() end
function treeset.intersect_inplace<T>(self: TreeSet<T>) end
function treeset.intersect<T>(self: TreeSet<T>) end
function treeset.union_inplace<T>(self: TreeSet<T>) end
function treeset.union<T>(self: TreeSet<T>) end
function treeset.subtract_inplace<T>(self: TreeSet<T>) end
function treeset.subtract<T>(self: TreeSet<T>, target)
	for key in target do
	end
end
function treeset.size<T>(self: TreeSet<T>) end
function treeset.has<T>(self: TreeSet<T>, value): boolean
	return self[value] or false
end
function treeset.add<T>(self: TreeSet<T>, value)
	self[value] = true
end
function treeset.exclusive_inplace<T>(self: TreeSet<T>) end
function treeset.exclusive<T>(self: TreeSet<T>) end
function treeset.is_subset_of<T>(self: TreeSet<T>, of) end

export type TreeSet<T> = { [T]: boolean } & typeof(treeset)

return treeset
